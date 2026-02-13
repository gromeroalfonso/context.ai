---
name: Fase 6B - Migración pgvector a Pinecone
overview: "Fase intermedia entre la Fase 6 (Auth) y la Fase 7 (Testing). Migración de la base de datos vectorial desde pgvector (PostgreSQL) a Pinecone como servicio gestionado, manteniendo PostgreSQL para datos relacionales. Incluye creación de interfaz abstracta, implementación del servicio Pinecone, refactorización del repositorio, migración de datos, actualización de CI/CD y validación end-to-end."
phase: "6B"
parent_phase: "009-plan-implementacion-detallado.md"
related_docs:
  - "014-migracion-pgvector-pinecone.md"
  - "015-deployment-cloud-architecture.md"
total_issues: 6
github_milestone: "Phase 6B: Pinecone Vector DB Migration"
github_label: "phase-6b"
---

# Fase 6B: Migración de pgvector a Pinecone

Fase anexa entre la Fase 6 (Autenticación y Autorización) y la Fase 7 (Testing e Integración). Se crea como **Fase 6B** para no alterar la numeración existente de fases, manteniendo la trazabilidad del proyecto.

## Contexto y Justificación

### ¿Por qué migrar?

| Aspecto | pgvector (actual) | Pinecone (objetivo) |
|---------|-------------------|---------------------|
| **Tipo** | Extensión PostgreSQL | Servicio gestionado (SaaS) |
| **Escalabilidad** | Limitada al servidor PostgreSQL | Auto-escalable, serverless |
| **Mantenimiento** | Requiere gestión de índices HNSW | Cero mantenimiento |
| **Deployment** | Requiere imagen `pgvector/pgvector:pg16` | API key + SDK |
| **Costo** | Incluido en PostgreSQL | Free tier: 100K vectores |
| **Rendimiento** | Bueno para <100K vectores | Optimizado para millones |
| **Backups** | Dependiente del backup de PostgreSQL | Automáticos por Pinecone |

### Beneficios para el proyecto

1. **Simplificación del deployment**: PostgreSQL estándar (sin extensión vector)
2. **Separación de concerns**: Datos relacionales en PostgreSQL, vectores en Pinecone
3. **Preparación para producción**: Pinecone es un servicio cloud-native
4. **Clean Architecture**: Interfaz `IVectorStore` permite cambiar implementación sin tocar lógica de negocio

---

## Resumen de Issues

| # | Issue | Prioridad | Estimación | Dependencias |
|---|-------|-----------|------------|--------------|
| 6B.1 | Setup Pinecone Account & Create IVectorStore Interface | 🔴 Alta | 2h | Ninguna |
| 6B.2 | Implement PineconeVectorStore Service | 🔴 Alta | 4h | 6B.1 |
| 6B.3 | Refactor KnowledgeRepository & Services | 🔴 Alta | 6h | 6B.2 |
| 6B.4 | Database Migration - Remove pgvector | 🔴 Alta | 3h | 6B.3 |
| 6B.5 | Update CI/CD Pipeline & Docker Configuration | 🟡 Media | 2h | 6B.3 |
| 6B.6 | Integration Tests & End-to-End Validation | 🔴 Alta | 4h | 6B.4, 6B.5 |
| | **Total** | | **21h** | |

### Diagrama de Dependencias

```
6B.1 (Interface) ──► 6B.2 (Pinecone Service) ──► 6B.3 (Refactor) ──┬──► 6B.4 (DB Migration) ──┐
                                                                     │                           │
                                                                     └──► 6B.5 (CI/CD)     ─────┤
                                                                                                 │
                                                                                                 ▼
                                                                                     6B.6 (Validation)
```

---

## Issue 6B.1: Setup Pinecone Account & Create IVectorStore Interface

**GitHub Issue:** #6  
**Prioridad:** 🔴 Alta  
**Estimación:** 2 horas  
**Dependencias:** Ninguna

### Descripción

Crear cuenta en Pinecone, configurar el índice, instalar el SDK, y crear la interfaz `IVectorStore` en la capa de dominio siguiendo el Principio de Inversión de Dependencias (DIP).

### Acceptance Criteria

- [ ] Cuenta de Pinecone creada en [pinecone.io](https://www.pinecone.io/)
- [ ] Índice `context-ai` creado con dimensions=3072, metric=cosine
- [ ] API key obtenida y añadida a `env-template.txt`
- [ ] Paquete `@pinecone-database/pinecone` instalado
- [ ] Interfaz `IVectorStore` creada en capa de dominio
- [ ] Tipos `VectorUpsertInput` y `VectorSearchResult` definidos
- [ ] Variables de entorno documentadas

### Files to Create

```
src/modules/knowledge/domain/services/vector-store.interface.ts   # IVectorStore interface
env-template.txt                                                   # Add PINECONE_* vars
```

### Technical Notes

**Configuración del Índice Pinecone:**

| Parámetro | Valor |
|-----------|-------|
| Nombre | `context-ai` |
| Dimensiones | 3072 |
| Métrica | cosine |
| Cloud | AWS (us-east-1) |
| Plan | Starter (free) |

**Diseño de la Interfaz:**

```typescript
export interface VectorUpsertInput {
  id: string;
  embedding: number[];
  metadata: {
    sourceId: string;
    sectorId: string;
    content: string;
    position: number;
    tokenCount: number;
  };
}

export interface VectorSearchResult {
  id: string;
  score: number;
  metadata: {
    sourceId: string;
    sectorId: string;
    content: string;
    position: number;
    tokenCount: number;
  };
}

export interface IVectorStore {
  upsertVectors(inputs: VectorUpsertInput[]): Promise<void>;
  vectorSearch(
    embedding: number[],
    sectorId: string,
    limit?: number,
    minScore?: number,
  ): Promise<VectorSearchResult[]>;
  deleteBySourceId(sourceId: string, sectorId: string): Promise<void>;
}
```

**Nuevas Variables de Entorno:**

```bash
# Pinecone Vector Database
PINECONE_API_KEY=pcsk_xxxxx
PINECONE_INDEX=context-ai
```

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] `pnpm test` passes
- [ ] Interfaz sigue principios de Clean Architecture / DDD

---

## Issue 6B.2: Implement PineconeVectorStore Service

**GitHub Issue:** #7  
**Prioridad:** 🔴 Alta  
**Estimación:** 4 horas  
**Dependencias:** 6B.1

### Descripción

Implementar el servicio `PineconeVectorStore` que implementa la interfaz `IVectorStore`. Este servicio utiliza el SDK de Pinecone para realizar operaciones vectoriales (upsert, search, delete).

### Acceptance Criteria

- [ ] Clase `PineconeVectorStore` creada implementando `IVectorStore`
- [ ] `PineconeModule` creado con inyección de dependencias correcta
- [ ] Upsert de vectores con metadata (sourceId, sectorId, position, tokenCount)
- [ ] Búsqueda por similitud con filtrado por namespace (sectorId)
- [ ] Eliminación de vectores por filtro sourceId
- [ ] Manejo de errores con excepciones custom
- [ ] Método de health check de conexión
- [ ] Tests unitarios con Pinecone client mockeado (>80% cobertura)

### Files to Create/Modify

```
src/modules/knowledge/infrastructure/services/pinecone-vector-store.service.ts           # Implementación
src/modules/knowledge/infrastructure/pinecone/pinecone.module.ts                          # Módulo NestJS
test/unit/modules/knowledge/infrastructure/services/pinecone-vector-store.service.spec.ts # Tests
```

### Technical Notes

**Estrategia de Namespaces en Pinecone:**

Usar `sectorId` como namespace de Pinecone para aislar vectores por sector:

```typescript
const index = this.pinecone.index(this.indexName);
const ns = index.namespace(sectorId);
```

**Schema de Metadata en Pinecone:**

```typescript
interface PineconeMetadata {
  sourceId: string;
  sectorId: string;
  content: string; // Texto del fragmento
  position: number;
  tokenCount: number;
}
```

**Batch Upsert:**

Pinecone recomienda batches de máximo 100 vectores por llamada de upsert:

```typescript
async upsertVectors(inputs: VectorUpsertInput[]): Promise<void> {
  const BATCH_SIZE = 100;
  const ns = this.index.namespace(inputs[0].metadata.sectorId);
  
  for (let i = 0; i < inputs.length; i += BATCH_SIZE) {
    const batch = inputs.slice(i, i + BATCH_SIZE);
    await ns.upsert(
      batch.map((input) => ({
        id: input.id,
        values: input.embedding,
        metadata: input.metadata,
      })),
    );
  }
}
```

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] `pnpm test` passes
- [ ] Tests unitarios pasan con >80% cobertura
- [ ] Servicio registrado en contenedor DI de NestJS

---

## Issue 6B.3: Refactor KnowledgeRepository & Services - Remove pgvector Dependency

**GitHub Issue:** #8  
**Prioridad:** 🔴 Alta  
**Estimación:** 6 horas  
**Dependencias:** 6B.2

### Descripción

Refactorizar el `KnowledgeRepository` y servicios relacionados para usar la interfaz `IVectorStore` en lugar de queries SQL directas contra pgvector. Eliminar la columna `embedding` del `FragmentModel` y actualizar el pipeline de ingestión de conocimiento para almacenar vectores en Pinecone.

### Acceptance Criteria

- [ ] `KnowledgeRepository.vectorSearch()` refactorizado para usar `IVectorStore`
- [ ] Pipeline de ingestión de fragmentos actualizado para upsert a Pinecone
- [ ] Columna `embedding` eliminada de la entidad `FragmentModel` TypeORM
- [ ] Paquete npm `pgvector` eliminado de dependencias
- [ ] Eliminación de source cascada a eliminación en Pinecone
- [ ] Todos los tests unitarios existentes actualizados y pasando
- [ ] Nuevos puntos de integración testeados

### Files to Modify

```
src/modules/knowledge/infrastructure/persistence/repositories/knowledge.repository.ts  # Eliminar SQL vectorSearch
src/modules/knowledge/infrastructure/persistence/models/fragment.model.ts              # Eliminar columna embedding
src/modules/knowledge/application/services/knowledge.service.ts                        # Usar IVectorStore en ingestión
src/modules/knowledge/application/services/rag.service.ts                              # Usar IVectorStore en búsqueda
src/modules/knowledge/knowledge.module.ts                                              # Actualizar bindings DI
package.json                                                                            # Eliminar paquete pgvector
```

### Technical Notes

**Flujo Actual (pgvector):**

```
Ingestión: Documento → Chunks → Embeddings → PostgreSQL (columna embedding)
Búsqueda:  Query → Embedding → SQL con operador <=> → Resultados
```

**Nuevo Flujo (Pinecone):**

```
Ingestión: Documento → Chunks → Embeddings → Pinecone upsert + PostgreSQL (solo metadata)
Búsqueda:  Query → Embedding → Pinecone query → Fragment IDs → PostgreSQL join → Resultados
```

**Puntos Clave de Refactorización:**

1. **Método vectorSearch**: Reemplazar SQL raw con `IVectorStore.vectorSearch()`
2. **Ingestión de fragmentos**: Después de crear fragmentos en PostgreSQL, upsert embeddings a Pinecone
3. **Eliminación de sources**: Añadir limpieza en Pinecone al eliminar knowledge sources
4. **FragmentModel**: Eliminar columna `embedding` (type: vector), mantener todas las demás

**Inyección de Dependencias:**

```typescript
// En knowledge.module.ts
providers: [
  {
    provide: 'IVectorStore',
    useClass: PineconeVectorStore,
  },
]
```

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] `pnpm test` passes
- [ ] Sin referencias a pgvector en código de aplicación
- [ ] Operaciones vectoriales completamente delegadas a IVectorStore
- [ ] Todos los tests actualizados para reflejar nueva arquitectura

---

## Issue 6B.4: Database Migration - Remove pgvector Extension & Embedding Column

**GitHub Issue:** #9  
**Prioridad:** 🔴 Alta  
**Estimación:** 3 horas  
**Dependencias:** 6B.3

### Descripción

Crear una migración TypeORM para eliminar la extensión pgvector, la columna `embedding` de la tabla `fragments`, y el índice HNSW. También crear un script de migración de datos que pueda re-embeber y upsert fragmentos existentes a Pinecone si es necesario.

### Acceptance Criteria

- [ ] Migración TypeORM creada para eliminar columna `embedding`
- [ ] Índice HNSW `idx_fragments_embedding_hnsw` eliminado
- [ ] Eliminación de extensión `vector` manejada correctamente
- [ ] Script de migración de datos para re-embeber fragmentos a Pinecone
- [ ] Migración es reversible (métodos up/down)
- [ ] Script maneja procesamiento por batches para datasets grandes
- [ ] Migración testeada localmente con Docker PostgreSQL

### Files to Create

```
src/migrations/TIMESTAMP-RemovePgvectorEmbeddings.ts           # Migración TypeORM
scripts/migrate-vectors-to-pinecone.ts                          # Script de migración de datos
```

### Technical Notes

**Migración TypeORM (Schema):**

```typescript
public async up(queryRunner: QueryRunner): Promise<void> {
  // 1. Eliminar índice HNSW
  await queryRunner.query(`DROP INDEX IF EXISTS idx_fragments_embedding_hnsw`);
  // 2. Eliminar columna embedding
  await queryRunner.query(`ALTER TABLE fragments DROP COLUMN IF EXISTS embedding`);
  // 3. Opcionalmente eliminar extensión vector
  await queryRunner.query(`DROP EXTENSION IF EXISTS vector`);
}

public async down(queryRunner: QueryRunner): Promise<void> {
  // 1. Recrear extensión vector
  await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS vector`);
  // 2. Recrear columna embedding
  await queryRunner.query(`ALTER TABLE fragments ADD COLUMN embedding vector(3072)`);
  // 3. Recrear índice HNSW
  await queryRunner.query(`
    CREATE INDEX idx_fragments_embedding_hnsw
    ON fragments USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
  `);
}
```

**Script de Migración de Datos:**

El script debe:
1. Consultar todos los fragmentos de PostgreSQL (con contenido)
2. Generar embeddings usando EmbeddingService (batch de 50)
3. Upsert a Pinecone con metadata correcta
4. Logear progreso y manejar fallos gracefully
5. Soportar flag `--dry-run`
6. Soportar flag `--sector-id` para migración parcial

**Orden de Ejecución:**

1. Ejecutar script de migración de datos PRIMERO (para poblar Pinecone)
2. Verificar que los datos en Pinecone son correctos
3. Ejecutar migración TypeORM para eliminar schema pgvector

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] `pnpm test` passes
- [ ] Migración ejecutada exitosamente en PostgreSQL Docker local
- [ ] Script de migración de datos testeado con datos de ejemplo
- [ ] Migración de rollback testeada

---

## Issue 6B.5: Update CI/CD Pipeline & Docker Configuration

**GitHub Issue:** #10  
**Prioridad:** 🟡 Media  
**Estimación:** 2 horas  
**Dependencias:** 6B.3

### Descripción

Actualizar el pipeline de GitHub Actions CI/CD y la configuración Docker para eliminar la dependencia de pgvector. El job de test en CI actualmente usa `pgvector/pgvector:pg16` como service container, que debe reemplazarse con `postgres:16` estándar. También actualizar `docker-compose.yml` para desarrollo local.

### Acceptance Criteria

- [ ] CI workflow actualizado: `pgvector/pgvector:pg16` → `postgres:16`
- [ ] `docker-compose.yml` actualizado: `pgvector/pgvector:pg16` → `postgres:16-alpine`
- [ ] `scripts/init-db.sql` actualizado: eliminar `CREATE EXTENSION vector`
- [ ] API key de Pinecone añadida como GitHub Secret
- [ ] Tests de CI pasan con PostgreSQL estándar (sin extensión vector)
- [ ] Documentación de variables de entorno actualizada
- [ ] `env-template.txt` incluye todas las variables de Pinecone

### Files to Modify

```
.github/workflows/ci.yml          # Actualizar imagen postgres service
docker-compose.yml                  # Actualizar imagen postgres service
scripts/init-db.sql                 # Eliminar extensión vector
env-template.txt                    # Añadir variables PINECONE_*
```

### Technical Notes

**Cambios en CI Workflow:**

```yaml
# Antes
services:
  postgres:
    image: pgvector/pgvector:pg16

# Después
services:
  postgres:
    image: postgres:16
```

**Cambios en Docker Compose:**

```yaml
# Antes
services:
  postgres:
    image: pgvector/pgvector:pg16

# Después
services:
  postgres:
    image: postgres:16-alpine
```

**GitHub Secrets a Añadir:**
- `PINECONE_API_KEY` — Para tests de integración en CI
- `PINECONE_INDEX` — Nombre del índice para CI

**Cambios en init-db.sql:**

Eliminar:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] Pipeline CI pasa con PostgreSQL estándar
- [ ] Docker compose arranca correctamente
- [ ] Todos los GitHub Secrets documentados

---

## Issue 6B.6: Integration Tests & End-to-End Validation

**GitHub Issue:** #11  
**Prioridad:** 🔴 Alta  
**Estimación:** 4 horas  
**Dependencias:** 6B.4, 6B.5

### Descripción

Crear tests de integración para el pipeline RAG completo basado en Pinecone y realizar validación end-to-end para asegurar que la migración de pgvector a Pinecone es completamente funcional. Este es el paso final de validación antes de considerar la migración completada.

### Acceptance Criteria

- [ ] Tests de integración para PineconeVectorStore con API real de Pinecone
- [ ] Test E2E: pipeline completo de ingestión (upload → chunk → embed → Pinecone)
- [ ] Test E2E: pipeline de query RAG (query → embed → Pinecone search → LLM response)
- [ ] Test E2E: eliminación de knowledge source cascada a Pinecone
- [ ] Comparación de rendimiento: pgvector vs Pinecone documentada
- [ ] Todos los tests unitarios existentes pasan (regression check)
- [ ] Pipeline CI completo pasa
- [ ] Checklist de QA manual completado

### Files to Create/Modify

```
test/integration/pinecone-vector-store.integration.spec.ts     # Tests de integración
test/e2e/knowledge-ingestion.e2e.spec.ts                       # Test E2E de ingestión
test/e2e/rag-query.e2e.spec.ts                                 # Test E2E de query RAG
```

### Technical Notes

**Setup de Tests de Integración:**

```typescript
// Usar namespace específico para tests en Pinecone
const TEST_NAMESPACE = `test-${Date.now()}`;

afterAll(async () => {
  // Limpiar vectores de test
  await pinecone.index(indexName).namespace(TEST_NAMESPACE).deleteAll();
});
```

**Escenarios de Test:**

1. **Vector Upsert & Search**
   - Upsert 10 vectores de test
   - Buscar con un vector query conocido
   - Verificar que resultados se devuelven en orden correcto
   - Verificar que scores de similitud están en rango esperado

2. **Pipeline RAG Completo**
   - Subir un documento PDF/texto de test
   - Verificar fragmentos creados en PostgreSQL
   - Verificar vectores insertados en Pinecone
   - Query con una pregunta relevante
   - Verificar que la respuesta usa el contenido subido como contexto

3. **Cascade de Eliminación**
   - Crear knowledge source con fragmentos
   - Eliminar el knowledge source
   - Verificar vectores eliminados de Pinecone
   - Verificar fragmentos eliminados de PostgreSQL

4. **Manejo de Errores**
   - Test de comportamiento cuando Pinecone no está accesible
   - Test con API key inválida
   - Test de manejo de rate limiting

**Checklist de QA Manual:**

- [ ] Subir un documento PDF y verificar que aparece en la base de conocimiento
- [ ] Hacer una pregunta relacionada con el documento subido
- [ ] Verificar que la respuesta cita las fuentes correctas
- [ ] Eliminar un knowledge source y verificar limpieza
- [ ] Revisar dashboard de Pinecone para conteo correcto de vectores
- [ ] Verificar que no hay referencias a pgvector en el schema de la base de datos

**Benchmarks de Rendimiento a Documentar:**

| Métrica | pgvector | Pinecone |
|---------|----------|----------|
| Vector upsert (100 vectores) | X ms | Y ms |
| Búsqueda por similitud (top 5) | X ms | Y ms |
| Eliminación de source (50 vectores) | X ms | Y ms |

### Definition of Done

- [ ] `pnpm lint` passes
- [ ] `pnpm build` passes
- [ ] `pnpm test` passes (todos los tests unitarios)
- [ ] Tests de integración pasan contra Pinecone real
- [ ] Benchmarks de rendimiento documentados
- [ ] QA manual completado
- [ ] Migración considerada **COMPLETA** ✅

---

## Branch Strategy

```
main
 └── feature/phase-6b-pinecone-migration    (rama principal de la fase)
      ├── feature/phase-6b-pinecone-setup          (6B.1 - Interface + Setup)
      ├── feature/phase-6b-pinecone-service        (6B.2 - Service Implementation)
      ├── feature/phase-6b-repository-refactor     (6B.3 - Repository Refactor)
      ├── feature/phase-6b-db-migration            (6B.4 - Database Migration)
      ├── feature/phase-6b-cicd-update             (6B.5 - CI/CD Update)
      └── feature/phase-6b-validation              (6B.6 - Integration Tests)
```

**Nota:** Siguiendo la política del proyecto, **NUNCA se eliminan las ramas feature/*** después del merge, ya que son necesarias para la validación y evaluación del TFM.

---

## Checklist Final de Migración

Antes de considerar la Fase 6B como completada:

- [ ] Pinecone account activo y configurado
- [ ] Índice `context-ai` creado y funcional
- [ ] `IVectorStore` interfaz implementada y testeada
- [ ] `PineconeVectorStore` service implementado y testeado
- [ ] `KnowledgeRepository` refactorizado sin pgvector
- [ ] Columna `embedding` eliminada de la tabla `fragments`
- [ ] Extensión `vector` eliminada de PostgreSQL
- [ ] Índice HNSW eliminado
- [ ] Paquete npm `pgvector` eliminado
- [ ] CI/CD actualizado con `postgres:16` estándar
- [ ] Docker Compose actualizado
- [ ] Variables de entorno de Pinecone documentadas
- [ ] Tests de integración pasando
- [ ] QA manual completado
- [ ] Benchmarks de rendimiento documentados
- [ ] Todas las ramas feature preservadas

