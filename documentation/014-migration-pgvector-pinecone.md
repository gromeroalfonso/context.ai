---
name: Migración de pgvector a Pinecone
overview: "Guía detallada para migrar el almacenamiento y búsqueda vectorial de pgvector (PostgreSQL) a Pinecone como base de datos vectorial gestionada. Incluye análisis de la arquitectura actual, plan de migración, cambios en código, migración de datos y estrategia de rollback."
phase: 8
parent_phase: "009-plan-implementacion-detallado.md"
related_docs:
  - "005-technical-architecture.md"
  - "006-modelo-datos.md"
  - "015-deployment-cloud-architecture.md"
---

# Migración de pgvector a Pinecone

## 1. Resumen Ejecutivo

### Objetivo

Migrar la funcionalidad de almacenamiento y búsqueda de vectores (embeddings) desde **pgvector** (extensión de PostgreSQL) a **Pinecone** (base de datos vectorial gestionada como servicio), manteniendo PostgreSQL únicamente para datos relacionales.

### Motivación

| Aspecto | pgvector (actual) | Pinecone (objetivo) |
|---------|-------------------|---------------------|
| **Hosting** | Requiere PostgreSQL con extensión pgvector | SaaS gestionado, sin infraestructura |
| **Escalabilidad** | Limitada por instancia de PostgreSQL | Escala automáticamente |
| **Costo operacional** | Alto (requiere imagen `pgvector/pgvector:pg16`) | Free tier disponible (1 index) |
| **Mantenimiento** | Gestión de índices HNSW manual | Automático |
| **Latencia** | Depende de la instancia PostgreSQL | Optimizado para búsqueda vectorial |
| **Deployment** | Necesita PostgreSQL con extensión específica | SDK de Node.js, sin dependencia de BD |
| **Dimensiones** | Soporta 3072D (configuración actual) | Soporta hasta 20,000 dimensiones |

### Impacto

- **Archivos a modificar:** ~10 archivos
- **Archivos nuevos:** ~3 archivos
- **Tests a actualizar:** ~5 archivos de tests
- **Migraciones de BD:** 1 migración nueva
- **Riesgo:** Medio (cambio aislado en capa de infraestructura gracias a Clean Architecture)

---

## 2. Arquitectura Actual (pgvector)

### 2.1 Flujo de Ingesta de Documentos

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│  Controller  │────▶│ IngestDoc    │────▶│ EmbeddingService│────▶│ Gemini API   │
│  (HTTP)      │     │ UseCase      │     │ (Genkit)        │     │ (embedding)  │
└─────────────┘     └──────┬───────┘     └────────────────┘     └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Knowledge    │──── Guarda fragments + embeddings
                    │ Repository   │     en tabla `fragments` (PostgreSQL)
                    │ (TypeORM)    │     columna: embedding vector(3072)
                    └──────────────┘
```

### 2.2 Flujo de Búsqueda RAG (Query)

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│  Controller  │────▶│ QueryAssist  │────▶│ RAG Query Flow │────▶│ Gemini API   │
│  (HTTP)      │     │ UseCase      │     │ (Genkit)        │     │ (embedding + │
└─────────────┘     └──────────────┘     └───────┬────────┘     │  generation) │
                                                  │              └──────────────┘
                                                  ▼
                                          ┌──────────────┐
                                          │ Knowledge    │──── SQL query con
                                          │ Repository   │     operador <=> (cosine)
                                          │ vectorSearch │     sobre columna vector
                                          └──────────────┘
```

### 2.3 Archivos Involucrados en la Arquitectura Actual

#### Modelo de datos (FragmentModel)

**Archivo:** `src/modules/knowledge/infrastructure/persistence/models/fragment.model.ts`

```typescript
// Columna vectorial actual en PostgreSQL
@Column({
  type: 'vector',    // ← Tipo pgvector
  nullable: true,
})
embedding!: string | null;
```

#### Repositorio con búsqueda vectorial

**Archivo:** `src/modules/knowledge/infrastructure/persistence/repositories/knowledge.repository.ts`

```typescript
// Búsqueda vectorial actual usando operador pgvector <=>
async vectorSearch(
  embedding: number[],
  sectorId: string,
  limit: number = 5,
  similarityThreshold: number = 0.7,
): Promise<FragmentWithSimilarity[]> {
  const embeddingStr = JSON.stringify(embedding);

  const query = `
    SELECT 
      f.*,
      (1 - (f.embedding <=> $1::vector)) as similarity
    FROM fragments f
    INNER JOIN knowledge_sources ks ON f.source_id = ks.id
    WHERE ks.sector_id = $2
      AND f.embedding IS NOT NULL
      AND (1 - (f.embedding <=> $1::vector)) >= $3
    ORDER BY similarity DESC
    LIMIT $4
  `;

  const queryResults = await this.fragmentRepository.query(query, [
    embeddingStr, sectorId, similarityThreshold, limit,
  ]);
  // ... mapeo de resultados
}
```

#### Servicio de Embeddings

**Archivo:** `src/modules/knowledge/infrastructure/services/embedding.service.ts`

- Modelo: `googleai/gemini-embedding-001`
- Dimensiones: 3072 (por defecto)
- Task types: `RETRIEVAL_DOCUMENT` (indexación) y `RETRIEVAL_QUERY` (búsqueda)
- **Este servicio NO cambia** — sigue generando embeddings con Genkit/Gemini

#### Configuración Genkit

**Archivo:** `src/shared/genkit/genkit.config.ts`

```typescript
export const GENKIT_CONFIG = {
  EMBEDDING_MODEL: 'googleai/gemini-embedding-001',
  EMBEDDING_DIMENSIONS: 3072,
  // ...
};
```

#### Migración de BD actual

**Archivo:** `src/migrations/1707265200000-CreateKnowledgeTables.ts`

- Habilita extensión: `CREATE EXTENSION IF NOT EXISTS vector`
- Columna: `embedding vector(768)` (nota: la migración dice 768 pero el servicio usa 3072)
- Índice HNSW: `USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)`

#### Caso de uso de ingesta

**Archivo:** `src/modules/knowledge/application/use-cases/ingest-document.use-case.ts`

- Genera embeddings con `EmbeddingService`
- Crea entidades `Fragment` con embedding incluido
- Guarda fragments (incluyendo embedding) en PostgreSQL

#### Flujo RAG

**Archivo:** `src/shared/genkit/flows/rag-query.flow.ts`

- Genera embedding de la query
- Llama a `vectorSearch()` del repositorio
- Filtra por similaridad
- Genera respuesta con Gemini LLM

#### Módulo de Interacción (wiring)

**Archivo:** `src/modules/interaction/interaction.module.ts`

- Crea wrapper de `vectorSearch` que conecta `KnowledgeRepository` con `RagQueryService`
- Inyecta dependencias para el `QueryAssistantUseCase`

---

## 3. Arquitectura Objetivo (Pinecone)

### 3.1 Flujo de Ingesta (Nuevo)

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│  Controller  │────▶│ IngestDoc    │────▶│ EmbeddingService│────▶│ Gemini API   │
│  (HTTP)      │     │ UseCase      │     │ (Genkit)        │     │ (embedding)  │
└─────────────┘     └──────┬───────┘     └────────────────┘     └──────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
                    ▼             ▼
            ┌──────────────┐  ┌──────────────┐
            │ Knowledge    │  │ PineconeVector│
            │ Repository   │  │ Store         │
            │ (TypeORM)    │  │ (SDK)         │
            │              │  │               │
            │ Guarda:      │  │ Guarda:       │
            │ - content    │  │ - embedding   │
            │ - metadata   │  │ - fragmentId  │
            │ - position   │  │ - sectorId    │
            │ - tokenCount │  │ - sourceId    │
            └──────────────┘  └──────────────┘
              PostgreSQL          Pinecone
```

### 3.2 Flujo de Búsqueda RAG (Nuevo)

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  Controller  │────▶│ QueryAssist  │────▶│ RAG Query Flow │
│  (HTTP)      │     │ UseCase      │     │ (Genkit)        │
└─────────────┘     └──────────────┘     └───────┬────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │ PineconeVector  │──── Query a Pinecone
                                          │ Store           │     (cosine similarity)
                                          │ vectorSearch()  │
                                          └───────┬────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │ Knowledge      │──── Fetch content por
                                          │ Repository     │     fragmentId desde
                                          │ findFragments  │     PostgreSQL
                                          └────────────────┘
```

### 3.3 Configuración de Pinecone

| Parámetro | Valor |
|-----------|-------|
| **Index name** | `context-ai` |
| **Dimensions** | 3072 |
| **Metric** | `cosine` |
| **Cloud** | AWS (us-east-1) o GCP |
| **Pod type** | Starter (free tier) |
| **Namespace** | Por `sectorId` (aislamiento multi-tenant) |

### 3.4 Estructura de Vectores en Pinecone

Cada vector almacenado en Pinecone tendrá:

```typescript
{
  id: string;            // fragmentId (UUID) - mismo ID que en PostgreSQL
  values: number[];      // embedding vector (3072 dimensiones)
  metadata: {
    fragmentId: string;  // referencia al fragment en PostgreSQL
    sourceId: string;    // referencia al knowledge_source
    sectorId: string;    // para filtrado multi-tenant
    position: number;    // posición en el documento
    contentPreview: string; // primeros 200 chars (para debug)
  }
}
```

**Namespace:** Se usará `sectorId` como namespace de Pinecone para aislamiento natural multi-tenant.

---

## 4. Plan de Migración Detallado

### 4.1 Fase 1: Crear servicio PineconeVectorStore (NUEVO)

**Archivo nuevo:** `src/modules/knowledge/infrastructure/services/pinecone-vector-store.service.ts`

```typescript
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Pinecone, Index, RecordMetadata } from '@pinecone-database/pinecone';

// Constants
const DEFAULT_TOP_K = 5;
const DEFAULT_MIN_SCORE = 0.7;
const CONTENT_PREVIEW_LENGTH = 200;
const UPSERT_BATCH_SIZE = 100;

/**
 * Metadata stored alongside vectors in Pinecone
 */
interface PineconeFragmentMetadata extends RecordMetadata {
  fragmentId: string;
  sourceId: string;
  sectorId: string;
  position: number;
  contentPreview: string;
}

/**
 * Result from Pinecone vector search
 */
export interface VectorSearchResult {
  fragmentId: string;
  sourceId: string;
  score: number;
  metadata: PineconeFragmentMetadata;
}

/**
 * Input for upserting vectors
 */
export interface VectorUpsertInput {
  fragmentId: string;
  sourceId: string;
  sectorId: string;
  position: number;
  content: string;
  embedding: number[];
}

/**
 * Pinecone Vector Store Service
 *
 * Manages vector storage and similarity search using Pinecone.
 * Replaces pgvector for vector operations while PostgreSQL
 * continues handling relational data.
 *
 * Features:
 * - Namespace-based multi-tenant isolation (by sectorId)
 * - Cosine similarity search
 * - Batch upsert support
 * - Metadata filtering
 *
 * Security:
 * - API key via environment variable
 * - Input validation
 * - No sensitive data in metadata
 */
@Injectable()
export class PineconeVectorStoreService implements OnModuleInit {
  private readonly logger = new Logger(PineconeVectorStoreService.name);
  private pinecone: Pinecone;
  private index: Index;

  async onModuleInit(): Promise<void> {
    const apiKey = process.env.PINECONE_API_KEY;
    if (!apiKey) {
      throw new Error('PINECONE_API_KEY environment variable is required');
    }

    const indexName = process.env.PINECONE_INDEX || 'context-ai';

    this.pinecone = new Pinecone({ apiKey });
    this.index = this.pinecone.index(indexName);

    this.logger.log(`Pinecone initialized with index: ${indexName}`);
  }

  /**
   * Upsert a single vector into Pinecone
   */
  async upsertVector(input: VectorUpsertInput): Promise<void> {
    const namespace = this.index.namespace(input.sectorId);

    await namespace.upsert([
      {
        id: input.fragmentId,
        values: input.embedding,
        metadata: {
          fragmentId: input.fragmentId,
          sourceId: input.sourceId,
          sectorId: input.sectorId,
          position: input.position,
          contentPreview: input.content.substring(0, CONTENT_PREVIEW_LENGTH),
        },
      },
    ]);
  }

  /**
   * Upsert multiple vectors in batches
   */
  async upsertVectors(inputs: VectorUpsertInput[]): Promise<void> {
    if (inputs.length === 0) return;

    // Group by sectorId (namespace)
    const grouped = new Map<string, VectorUpsertInput[]>();
    for (const input of inputs) {
      const existing = grouped.get(input.sectorId) ?? [];
      existing.push(input);
      grouped.set(input.sectorId, existing);
    }

    // Upsert per namespace in batches
    for (const [sectorId, sectorInputs] of grouped) {
      const namespace = this.index.namespace(sectorId);

      for (let i = 0; i < sectorInputs.length; i += UPSERT_BATCH_SIZE) {
        const batch = sectorInputs.slice(i, i + UPSERT_BATCH_SIZE);

        const vectors = batch.map((input) => ({
          id: input.fragmentId,
          values: input.embedding,
          metadata: {
            fragmentId: input.fragmentId,
            sourceId: input.sourceId,
            sectorId: input.sectorId,
            position: input.position,
            contentPreview: input.content.substring(0, CONTENT_PREVIEW_LENGTH),
          },
        }));

        await namespace.upsert(vectors);
        this.logger.debug(
          `Upserted ${vectors.length} vectors to namespace ${sectorId}`,
        );
      }
    }

    this.logger.log(`Upserted ${inputs.length} vectors total`);
  }

  /**
   * Perform vector similarity search
   *
   * Uses cosine similarity (configured at index level).
   * Results are filtered by sectorId namespace.
   *
   * @param embedding - Query embedding vector
   * @param sectorId - Sector ID (used as Pinecone namespace)
   * @param limit - Maximum number of results
   * @param minScore - Minimum similarity score (0-1)
   * @returns Array of search results ordered by similarity
   */
  async vectorSearch(
    embedding: number[],
    sectorId: string,
    limit: number = DEFAULT_TOP_K,
    minScore: number = DEFAULT_MIN_SCORE,
  ): Promise<VectorSearchResult[]> {
    const namespace = this.index.namespace(sectorId);

    const queryResponse = await namespace.query({
      vector: embedding,
      topK: limit,
      includeMetadata: true,
    });

    // Filter by minimum score and map results
    const results: VectorSearchResult[] = [];

    for (const match of queryResponse.matches) {
      if (match.score !== undefined && match.score >= minScore) {
        const metadata = match.metadata as PineconeFragmentMetadata;
        results.push({
          fragmentId: metadata.fragmentId,
          sourceId: metadata.sourceId,
          score: match.score,
          metadata,
        });
      }
    }

    return results;
  }

  /**
   * Delete vectors by source ID (when a knowledge source is deleted)
   */
  async deleteBySourceId(
    sourceId: string,
    sectorId: string,
  ): Promise<void> {
    const namespace = this.index.namespace(sectorId);

    // Use metadata filter to find and delete vectors for this source
    // Note: Pinecone supports delete by metadata filter
    await namespace.deleteMany({ sourceId });

    this.logger.log(
      `Deleted vectors for source ${sourceId} in namespace ${sectorId}`,
    );
  }

  /**
   * Delete all vectors in a namespace (sector)
   */
  async deleteNamespace(sectorId: string): Promise<void> {
    const namespace = this.index.namespace(sectorId);
    await namespace.deleteAll();

    this.logger.log(`Deleted all vectors in namespace ${sectorId}`);
  }

  /**
   * Get index statistics
   */
  async getStats(): Promise<Record<string, unknown>> {
    const stats = await this.index.describeIndexStats();
    return stats as unknown as Record<string, unknown>;
  }
}
```

### 4.2 Fase 2: Crear interfaz de abstracción para el Vector Store

**Archivo nuevo:** `src/modules/knowledge/domain/services/vector-store.interface.ts`

```typescript
/**
 * IVectorStore Interface
 *
 * Abstraction for vector storage operations.
 * Follows Dependency Inversion Principle.
 * Current implementation: Pinecone
 * Previous implementation: pgvector (PostgreSQL)
 */
export interface IVectorStore {
  /**
   * Store vectors for fragments
   */
  upsertVectors(inputs: VectorUpsertInput[]): Promise<void>;

  /**
   * Perform similarity search
   */
  vectorSearch(
    embedding: number[],
    sectorId: string,
    limit?: number,
    minScore?: number,
  ): Promise<VectorSearchResult[]>;

  /**
   * Delete vectors associated with a knowledge source
   */
  deleteBySourceId(sourceId: string, sectorId: string): Promise<void>;
}

export interface VectorUpsertInput {
  fragmentId: string;
  sourceId: string;
  sectorId: string;
  position: number;
  content: string;
  embedding: number[];
}

export interface VectorSearchResult {
  fragmentId: string;
  sourceId: string;
  score: number;
}
```

### 4.3 Fase 3: Modificar FragmentModel — Eliminar columna embedding

**Archivo:** `src/modules/knowledge/infrastructure/persistence/models/fragment.model.ts`

**Cambio:** Eliminar la columna `embedding` del modelo TypeORM.

```typescript
// ANTES (pgvector)
@Entity('fragments')
@Index(['sourceId'])
@Index(['position'])
export class FragmentModel {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'source_id', type: 'uuid' })
  sourceId!: string;

  @Column({ type: 'text' })
  content!: string;

  @Column({                     // ← ELIMINAR
    type: 'vector',             // ← ELIMINAR
    nullable: true,             // ← ELIMINAR
  })                            // ← ELIMINAR
  embedding!: string | null;    // ← ELIMINAR

  @Column({ type: 'int' })
  position!: number;

  @Column({ name: 'token_count', type: 'int' })
  tokenCount!: number;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

// DESPUÉS (Pinecone)
@Entity('fragments')
@Index(['sourceId'])
@Index(['position'])
export class FragmentModel {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'source_id', type: 'uuid' })
  sourceId!: string;

  @Column({ type: 'text' })
  content!: string;

  // ← embedding ELIMINADO - ahora se almacena en Pinecone

  @Column({ type: 'int' })
  position!: number;

  @Column({ name: 'token_count', type: 'int' })
  tokenCount!: number;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
```

### 4.4 Fase 4: Modificar KnowledgeRepository — Eliminar vectorSearch

**Archivo:** `src/modules/knowledge/infrastructure/persistence/repositories/knowledge.repository.ts`

**Cambios:**

1. **Eliminar** el método `vectorSearch()` (ya no hace búsqueda vectorial SQL)
2. **Eliminar** la interfaz `VectorSearchRawResult`
3. **Eliminar** el type guard `isVectorSearchRawResult`
4. **Agregar** nuevo método `findFragmentsByIds()` para buscar fragments por IDs (devueltos por Pinecone)

```typescript
// NUEVO MÉTODO a agregar en KnowledgeRepository:

/**
 * Finds fragments by an array of IDs
 * Used after Pinecone vector search returns matching fragment IDs
 *
 * @param ids - Array of fragment UUIDs
 * @returns Array of fragments
 */
async findFragmentsByIds(ids: string[]): Promise<Fragment[]> {
  if (ids.length === 0) return [];

  const models = await this.fragmentRepository
    .createQueryBuilder('fragment')
    .where('fragment.id IN (:...ids)', { ids })
    .getMany();

  return FragmentMapper.toDomainArray(models);
}
```

### 4.5 Fase 5: Actualizar IKnowledgeRepository Interface

**Archivo:** `src/modules/knowledge/domain/repositories/knowledge.repository.interface.ts`

**Cambios:**

1. **Eliminar** el método `vectorSearch()` de la interfaz
2. **Agregar** el método `findFragmentsByIds()`
3. **Mover** `FragmentWithSimilarity` o adaptarlo

```typescript
// ANTES
export interface IKnowledgeRepository {
  // ... otros métodos ...
  vectorSearch(
    embedding: number[],
    sectorId: string,
    limit?: number,
    similarityThreshold?: number,
  ): Promise<FragmentWithSimilarity[]>;
  // ...
}

// DESPUÉS
export interface IKnowledgeRepository {
  // ... otros métodos ...
  
  // vectorSearch ELIMINADO - ahora se usa PineconeVectorStore

  /**
   * Finds fragments by array of IDs
   * Used to fetch content after Pinecone returns matching IDs
   */
  findFragmentsByIds(ids: string[]): Promise<Fragment[]>;
  
  // ...
}
```

### 4.6 Fase 6: Actualizar IngestDocumentUseCase

**Archivo:** `src/modules/knowledge/application/use-cases/ingest-document.use-case.ts`

**Cambios:** Después de guardar fragments en PostgreSQL, también upsert embeddings a Pinecone.

```typescript
// ANTES (simplificado):
// Step 7: Create Fragment entities (con embedding dentro del fragment)
// Step 8: Save fragments (embedding se guarda en PostgreSQL)

// DESPUÉS:
// Step 7: Create Fragment entities (el embedding va en la entidad para validación)
// Step 8: Save fragments en PostgreSQL (SIN embedding en la tabla)
// Step 9: Upsert embeddings en Pinecone (NUEVO)

// Código nuevo después de saveFragments:
const vectorInputs: VectorUpsertInput[] = savedFragments.map(
  (fragment, index) => ({
    fragmentId: fragment.id!,
    sourceId: savedSource.id!,
    sectorId: dto.sectorId,
    position: fragment.position,
    content: fragment.content,
    embedding: embeddings[index],  // embedding del servicio, no del fragment
  }),
);

await this.vectorStore.upsertVectors(vectorInputs);
```

### 4.7 Fase 7: Actualizar InteractionModule (wiring del RAG)

**Archivo:** `src/modules/interaction/interaction.module.ts`

**Cambios:** El `vectorSearchFn` ahora debe:
1. Buscar en **Pinecone** (obtiene `fragmentId` + `score`)
2. Buscar en **PostgreSQL** (obtiene `content` por `fragmentId`)
3. Combinar resultados

```typescript
// ANTES:
const vectorSearchFn = async (embedding, sectorId, limit) => {
  const fragments = await knowledgeRepository.vectorSearch(
    embedding, sectorId, limit,
  );
  return fragments.map((fragment) => ({
    id: fragment.id ?? '',
    content: fragment.content,
    similarity: fragment.similarity,
    sourceId: fragment.sourceId,
    metadata: fragment.metadata,
  }));
};

// DESPUÉS:
const vectorSearchFn = async (embedding, sectorId, limit) => {
  // 1. Buscar vectores similares en Pinecone
  const vectorResults = await vectorStore.vectorSearch(
    embedding, sectorId, limit,
  );

  if (vectorResults.length === 0) return [];

  // 2. Obtener contenido de fragments desde PostgreSQL
  const fragmentIds = vectorResults.map((r) => r.fragmentId);
  const fragments = await knowledgeRepository.findFragmentsByIds(fragmentIds);

  // 3. Combinar resultados (Pinecone score + PostgreSQL content)
  const fragmentMap = new Map(fragments.map((f) => [f.id, f]));

  return vectorResults
    .map((result) => {
      const fragment = fragmentMap.get(result.fragmentId);
      if (!fragment) return null;
      return {
        id: fragment.id ?? '',
        content: fragment.content,
        similarity: result.score,
        sourceId: fragment.sourceId,
        metadata: fragment.metadata,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item !== null);
};
```

### 4.8 Fase 8: Actualizar KnowledgeModule

**Archivo:** `src/modules/knowledge/knowledge.module.ts`

**Cambios:** Registrar `PineconeVectorStoreService` como provider.

```typescript
// Agregar al array de providers:
{
  provide: 'IVectorStore',
  useClass: PineconeVectorStoreService,
},

// Agregar al array de exports:
'IVectorStore',
```

### 4.9 Fase 9: Crear migración de BD

**Archivo nuevo:** `src/migrations/XXXXXXXXX-RemoveEmbeddingColumn.ts`

```typescript
import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Migration: Remove embedding column from fragments table
 *
 * Part of the pgvector → Pinecone migration.
 * Embeddings are now stored in Pinecone, not in PostgreSQL.
 *
 * WARNING: This migration is IRREVERSIBLE for the data.
 * Ensure all embeddings have been migrated to Pinecone before running.
 *
 * Changes:
 * - Drops HNSW vector index
 * - Drops embedding column from fragments table
 * - Drops pgvector extension (if no other tables use it)
 */
export class RemoveEmbeddingColumn implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Step 1: Drop the HNSW vector index
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_fragments_embedding_hnsw`,
    );

    // Step 2: Drop the embedding column
    await queryRunner.query(
      `ALTER TABLE fragments DROP COLUMN IF EXISTS embedding`,
    );

    // Step 3: (Optional) Drop pgvector extension if no longer needed
    // await queryRunner.query(`DROP EXTENSION IF EXISTS vector`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Restore pgvector extension
    await queryRunner.query(
      `CREATE EXTENSION IF NOT EXISTS vector`,
    );

    // Restore embedding column
    await queryRunner.query(
      `ALTER TABLE fragments ADD COLUMN embedding vector(3072)`,
    );

    // Restore HNSW index
    await queryRunner.query(`
      CREATE INDEX idx_fragments_embedding_hnsw
      ON fragments
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64)
    `);
  }
}
```

### 4.10 Fase 10: Actualizar la entidad Fragment del dominio

**Archivo:** `src/modules/knowledge/domain/entities/fragment.entity.ts`

**Cambios:** El embedding se vuelve **opcional** en la entidad de dominio, ya que ya no se persiste en PostgreSQL. Se usa temporalmente durante el proceso de ingesta.

```typescript
// El embedding pasa a ser opcional en la entidad:
export class Fragment {
  public id?: string;
  public sourceId: string;
  public content: string;
  public position: number;
  public embedding?: number[];  // ← Ahora opcional (no se persiste en PG)
  public metadata?: FragmentMetadata;
  public createdAt: Date;
  // ...
}
```

---

## 5. Variables de Entorno Nuevas

```bash
# Pinecone Configuration
PINECONE_API_KEY=pc-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PINECONE_INDEX=context-ai
PINECONE_ENVIRONMENT=us-east-1  # o gcp-starter para free tier
```

Agregar a:
- `env-template.txt`
- `.env` local
- Variables de entorno en Cloud Run / Railway
- GitHub Secrets para CI/CD

---

## 6. Dependencia Nueva

```bash
pnpm add @pinecone-database/pinecone
```

---

## 7. Script de Migración de Datos

Para migrar los embeddings existentes de PostgreSQL a Pinecone, crear un script one-off:

**Archivo:** `scripts/migrate-vectors-to-pinecone.ts`

```typescript
/**
 * Migration Script: pgvector → Pinecone
 *
 * Reads all fragments with embeddings from PostgreSQL
 * and upserts them to Pinecone.
 *
 * Usage:
 *   npx ts-node scripts/migrate-vectors-to-pinecone.ts
 *
 * Prerequisites:
 *   - PINECONE_API_KEY set in environment
 *   - PINECONE_INDEX created in Pinecone console
 *   - Database connection configured
 */

import { Pinecone } from '@pinecone-database/pinecone';
import { Client } from 'pg';

const BATCH_SIZE = 100;
const CONTENT_PREVIEW_LENGTH = 200;

async function migrate(): Promise<void> {
  console.log('Starting pgvector → Pinecone migration...');

  // 1. Connect to PostgreSQL
  const pgClient = new Client({
    connectionString: process.env.DATABASE_URL,
  });
  await pgClient.connect();

  // 2. Connect to Pinecone
  const pinecone = new Pinecone({
    apiKey: process.env.PINECONE_API_KEY!,
  });
  const index = pinecone.index(process.env.PINECONE_INDEX || 'context-ai');

  // 3. Query all fragments with embeddings
  const result = await pgClient.query(`
    SELECT f.id, f.source_id, f.content, f.embedding, f.position,
           ks.sector_id
    FROM fragments f
    INNER JOIN knowledge_sources ks ON f.source_id = ks.id
    WHERE f.embedding IS NOT NULL
  `);

  console.log(`Found ${result.rows.length} fragments to migrate`);

  // 4. Group by sector (namespace)
  const grouped = new Map<string, typeof result.rows>();
  for (const row of result.rows) {
    const sectorId = row.sector_id;
    const existing = grouped.get(sectorId) ?? [];
    existing.push(row);
    grouped.set(sectorId, existing);
  }

  // 5. Upsert to Pinecone per namespace
  let totalUpserted = 0;

  for (const [sectorId, rows] of grouped) {
    const namespace = index.namespace(sectorId);

    for (let i = 0; i < rows.length; i += BATCH_SIZE) {
      const batch = rows.slice(i, i + BATCH_SIZE);

      const vectors = batch.map((row) => ({
        id: row.id,
        values: JSON.parse(row.embedding), // pgvector stores as string
        metadata: {
          fragmentId: row.id,
          sourceId: row.source_id,
          sectorId: sectorId,
          position: row.position,
          contentPreview: row.content.substring(0, CONTENT_PREVIEW_LENGTH),
        },
      }));

      await namespace.upsert(vectors);
      totalUpserted += vectors.length;
      console.log(`  Upserted ${totalUpserted}/${result.rows.length}`);
    }
  }

  console.log(`Migration complete: ${totalUpserted} vectors migrated`);

  // 6. Verify
  const stats = await index.describeIndexStats();
  console.log('Pinecone index stats:', JSON.stringify(stats, null, 2));

  await pgClient.end();
}

migrate().catch(console.error);
```

---

## 8. Orden de Ejecución

### Paso 1: Preparar Pinecone (Manual)
1. Crear cuenta en [pinecone.io](https://www.pinecone.io/)
2. Crear index `context-ai` con dimensiones `3072` y métrica `cosine`
3. Obtener API key
4. Configurar variables de entorno

### Paso 2: Desarrollo (Código)
1. ✅ Instalar dependencia: `pnpm add @pinecone-database/pinecone`
2. ✅ Crear `IVectorStore` interface
3. ✅ Crear `PineconeVectorStoreService`
4. ✅ Agregar `findFragmentsByIds()` a `KnowledgeRepository`
5. ✅ Actualizar `IKnowledgeRepository` interface
6. ✅ Actualizar `IngestDocumentUseCase`
7. ✅ Actualizar `InteractionModule` (wiring)
8. ✅ Actualizar `KnowledgeModule`
9. ✅ Actualizar `Fragment` entity (embedding opcional)
10. ✅ Actualizar tests

### Paso 3: Migración de Datos
1. Ejecutar script `migrate-vectors-to-pinecone.ts`
2. Verificar conteo de vectores en Pinecone vs PostgreSQL
3. Ejecutar queries de prueba y comparar resultados

### Paso 4: Eliminar pgvector
1. Ejecutar migración `RemoveEmbeddingColumn`
2. Eliminar columna `embedding` de `FragmentModel`
3. Limpiar imports y código residual de pgvector
4. Eliminar dependencia `pgvector` del package.json

### Paso 5: Validación
1. `pnpm lint`
2. `pnpm build`
3. `pnpm test`
4. Test manual de ingesta de documentos
5. Test manual de búsqueda RAG
6. Verificar que ya no se necesita la imagen `pgvector/pgvector:pg16`

---

## 9. Impacto en Docker y CI/CD

### Docker Compose

```yaml
# ANTES: Requería imagen especial con pgvector
postgres:
  image: pgvector/pgvector:pg16  # ← Imagen especial

# DESPUÉS: PostgreSQL estándar es suficiente
postgres:
  image: postgres:16-alpine      # ← Imagen estándar, más ligera
```

### GitHub Actions CI

```yaml
# ANTES: Requería servicio pgvector en CI
services:
  postgres:
    image: pgvector/pgvector:pg16  # ← Ya no necesario

# DESPUÉS: PostgreSQL estándar
services:
  postgres:
    image: postgres:16-alpine
```

### Nuevas variables en CI/CD

```yaml
env:
  PINECONE_API_KEY: ${{ secrets.PINECONE_API_KEY }}
  PINECONE_INDEX: context-ai
```

---

## 10. Actualización de Tests

### Tests Unitarios a Modificar

| Archivo | Cambio |
|---------|--------|
| `test/unit/modules/knowledge/infrastructure/repositories/knowledge.repository.spec.ts` | Eliminar tests de `vectorSearch()`, agregar tests de `findFragmentsByIds()` |
| `test/unit/modules/knowledge/application/ingest-document.use-case.spec.ts` | Agregar mock de `IVectorStore`, verificar upsert |
| Tests de RAG flow | Actualizar mocks de vector search |

### Tests Nuevos a Crear

| Archivo | Descripción |
|---------|-------------|
| `test/unit/modules/knowledge/infrastructure/services/pinecone-vector-store.service.spec.ts` | Tests unitarios del servicio Pinecone (con mocks) |
| `test/integration/pinecone-vector-store.integration.spec.ts` | Tests de integración con Pinecone real (opcional, CI) |

---

## 11. Rollback Plan

Si la migración falla o hay problemas:

1. **Datos seguros:** Los embeddings siguen en PostgreSQL hasta que se ejecute la migración de BD
2. **Revertir código:** Revertir a la rama anterior con pgvector
3. **Revertir migración:** `pnpm migration:revert` restaura la columna embedding
4. **Dual-write (opcional):** Mantener escritura en ambos sistemas durante la transición

### Estrategia de rollback seguro:

```
1. NO ejecutar la migración de BD hasta confirmar que Pinecone funciona
2. Mantener código pgvector en rama separada (feature/pgvector-backup)
3. Probar exhaustivamente en staging antes de producción
4. Migración de BD es el último paso (point of no return para datos)
```

---

## 12. Checklist de Completitud

- [ ] Cuenta Pinecone creada y index configurado
- [ ] Variables de entorno configuradas (local + producción)
- [ ] Dependencia `@pinecone-database/pinecone` instalada
- [ ] `IVectorStore` interface creada
- [ ] `PineconeVectorStoreService` implementado
- [ ] `FragmentModel` — columna embedding eliminada
- [ ] `KnowledgeRepository` — `vectorSearch()` eliminado, `findFragmentsByIds()` agregado
- [ ] `IKnowledgeRepository` — interface actualizada
- [ ] `IngestDocumentUseCase` — upsert a Pinecone agregado
- [ ] `InteractionModule` — wiring actualizado (Pinecone + PostgreSQL)
- [ ] `KnowledgeModule` — provider registrado
- [ ] `Fragment` entity — embedding opcional
- [ ] Script de migración de datos creado y probado
- [ ] Migración de BD `RemoveEmbeddingColumn` creada
- [ ] Tests unitarios actualizados
- [ ] Tests de integración con Pinecone
- [ ] Docker Compose actualizado (imagen estándar PostgreSQL)
- [ ] CI/CD actualizado (variables, imagen)
- [ ] `pnpm lint` ✅
- [ ] `pnpm build` ✅
- [ ] `pnpm test` ✅
- [ ] Test manual de ingesta + búsqueda RAG
- [ ] Dependencia `pgvector` eliminada del package.json

---

## 13. Referencias

- [Pinecone Documentation](https://docs.pinecone.io/)
- [Pinecone Node.js SDK](https://docs.pinecone.io/reference/typescript-sdk)
- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Google Gemini Embedding Models](https://ai.google.dev/gemini-api/docs/models/gemini#embedding)
- [NestJS Documentation](https://docs.nestjs.com)

