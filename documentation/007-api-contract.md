# Contratos de API - Context.ai
## Documentación de Endpoints REST y DTOs Compartidos
### Actualizado: Febrero 2026

---

## 1. Visión General

Context.ai expone una **API RESTful** implementada con NestJS 11, documentada con Swagger/OpenAPI.

### Arquitectura de Comunicación

```
┌─────────────────────────┐
│   context-ai-front      │
│   (Next.js 16)          │
│                         │
│   NextAuth.js v5        │
│   + Auth0 provider      │
└──────────┬──────────────┘
           │ HTTP + JWT (Authorization: Bearer)
           │ X-Internal-API-Key (server-to-server)
           ▼
┌─────────────────────────┐
│   context-ai-api        │
│   (NestJS 11)           │
│                         │
│   Passport-JWT + JWKS   │
│   RBAC Guards           │
└──────────┬──────────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌──────────┐ ┌──────────┐
│PostgreSQL│ │ Pinecone │
│   16     │ │(vectors) │
└──────────┘ └──────────┘

┌─────────────────────────┐
│   context-ai-shared     │
│   (DTOs TypeScript)     │ ← Importado por front y back
└─────────────────────────┘
```

---

## 2. Configuración Base

### Base URL

```
Development:  http://localhost:3001
Production:   https://api.context.ai
```

> **⚠️ Cambio vs diseño original**: No se usa versionado por URL Path (`/api/v1/...`). Los endpoints se exponen directamente en la raíz (ej: `/interaction/query`, `/knowledge/documents/upload`).

### Documentación Interactiva (Swagger)

```
http://localhost:3001/api/docs
```

### Autenticación

**Endpoints protegidos** (por defecto): Requieren JWT Bearer token validado contra Auth0 JWKS.

```http
Authorization: Bearer <ACCESS_TOKEN>
```

**Endpoints públicos**: Decorados con `@Public()` (no requieren JWT):
- `GET /` — Health check

**Endpoints server-to-server**: Usan `X-Internal-API-Key` en lugar de JWT:
- `POST /users/sync` — Sincronización de usuario desde NextAuth

```http
X-Internal-API-Key: <INTERNAL_API_KEY>
```

---

## 3. Módulos de la API

| Módulo | Prefijo | Descripción | Endpoints |
|--------|---------|-------------|-----------|
| Health | `/` | Status de la API | 1 |
| Users | `/users` | Gestión de usuarios | 2 |
| Knowledge | `/knowledge` | Ingesta y gestión de documentos | 2 |
| Interaction | `/interaction` | Chat RAG y conversaciones | 4 |

**Total endpoints implementados**: 9

---

## 4. DTOs Compartidos (context-ai-shared)

### Estructura del Repositorio

```
context-ai-shared/
├── src/
│   ├── dto/
│   │   ├── auth/
│   │   │   ├── login.dto.ts
│   │   │   └── user.dto.ts
│   │   ├── knowledge/
│   │   │   ├── ingest-document.dto.ts
│   │   │   ├── knowledge-source.dto.ts
│   │   │   └── fragment.dto.ts
│   │   ├── interaction/
│   │   │   ├── chat-query.dto.ts
│   │   │   ├── chat-response.dto.ts
│   │   │   ├── message.dto.ts
│   │   │   └── source-fragment.dto.ts
│   │   └── index.ts
│   ├── types/
│   │   ├── entities/
│   │   │   ├── user.type.ts
│   │   │   ├── sector.type.ts
│   │   │   └── role.type.ts
│   │   ├── enums/
│   │   │   ├── source-type.enum.ts
│   │   │   ├── source-status.enum.ts
│   │   │   ├── role-type.enum.ts
│   │   │   └── message-role.enum.ts
│   │   └── index.ts
│   ├── validators/
│   │   └── index.ts
│   └── index.ts
├── package.json
└── tsconfig.json
```

### Enums Compartidos

```typescript
// SourceType
export enum SourceType {
  PDF = 'PDF',
  MARKDOWN = 'MARKDOWN',
}

// SourceStatus
export enum SourceStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  DELETED = 'DELETED',
}

// MessageRole
export enum MessageRole {
  USER = 'USER',
  ASSISTANT = 'ASSISTANT',
  SYSTEM = 'SYSTEM',
}

// RoleType
export enum RoleType {
  ADMIN = 'ADMIN',
  CONTENT_MANAGER = 'CONTENT_MANAGER',
  USER = 'USER',
  VIEWER = 'VIEWER',
}
```

### Instalación

```bash
# En context-ai-api y context-ai-front
pnpm add link:../context-ai-shared
```

---

## 5. Endpoints

### 5.1 Health Check

#### **GET** `/`

Verifica que el servidor está funcionando.

**Autenticación**: Ninguna (`@Public()`)

**Response**: `200 OK`
```
Hello World!
```

---

### 5.2 Users — Sincronización y Perfil

#### **POST** `/users/sync`

Sincroniza un usuario desde Auth0 al sistema interno. Crea el usuario si no existe, o actualiza `lastLoginAt` si ya existe.

**Autenticación**: `X-Internal-API-Key` header (server-to-server, NOT JWT)

**Request**:
```http
POST /users/sync
Content-Type: application/json
X-Internal-API-Key: <INTERNAL_API_KEY>
```

```json
{
  "auth0UserId": "auth0|123456789",
  "email": "usuario@example.com",
  "name": "Juan Pérez"
}
```

**Response**: `200 OK`
```json
{
  "id": "019405f8-6d84-7000-8000-123456789abc",
  "auth0UserId": "auth0|123456789",
  "email": "usuario@example.com",
  "name": "Juan Pérez",
  "isActive": true,
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": "2026-02-03T14:22:00Z",
  "lastLoginAt": "2026-02-03T14:22:00Z"
}
```

**Flujo**: NextAuth.js JWT callback → `POST /users/sync` → Obtiene userId interno → Almacena en JWT session

---

#### **GET** `/users/profile`

Obtiene el perfil del usuario autenticado.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `profile:read`

**Request**:
```http
GET /users/profile
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "id": "019405f8-6d84-7000-8000-123456789abc",
  "auth0UserId": "auth0|123456789",
  "email": "usuario@example.com",
  "name": "Juan Pérez",
  "isActive": true,
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": "2026-02-03T14:22:00Z",
  "lastLoginAt": "2026-02-03T14:22:00Z"
}
```

---

### 5.3 Knowledge — Ingesta y Gestión de Documentos

#### **POST** `/knowledge/documents/upload`

Sube y procesa un documento (PDF, Markdown o texto plano). El documento se parsea, se fragmenta en chunks, se generan embeddings con `gemini-embedding-001`, y se almacenan los vectores en Pinecone.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `knowledge:create`  
**Content-Type**: `multipart/form-data`

**Request**:
```http
POST /knowledge/documents/upload
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: multipart/form-data

------WebKitFormBoundary
Content-Disposition: form-data; name="title"

Manual de Vacaciones 2026
------WebKitFormBoundary
Content-Disposition: form-data; name="sectorId"

10000000-0000-0000-0000-000000000001
------WebKitFormBoundary
Content-Disposition: form-data; name="sourceType"

PDF
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="manual-vacaciones.pdf"
Content-Type: application/pdf

<BINARY_DATA>
------WebKitFormBoundary--
```

**Campos del form**:
| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `file` | Binary | ✅ | Archivo (PDF, MD, TXT) |
| `title` | String | ✅ | Título del documento (max 255 chars) |
| `sectorId` | UUID | ✅ | ID del sector |
| `sourceType` | Enum | ✅ | `PDF`, `MARKDOWN`, `URL` |
| `metadata` | JSON | ❌ | Metadatos opcionales |

**Validaciones**:
- Tamaño máximo: 10 MB
- MIME types permitidos: `application/pdf`, `text/markdown`, `text/plain`
- Título: 1-255 caracteres
- sectorId: UUID válido

**Response**: `201 Created`
```json
{
  "sourceId": "019405fa-0000-7000-8000-000000000001",
  "title": "Manual de Vacaciones 2026",
  "fragmentCount": 45,
  "status": "completed"
}
```

**Errores**:
- `400 Bad Request` — Archivo faltante, tipo inválido, validación fallida
- `401 Unauthorized` — JWT inválido o ausente
- `403 Forbidden` — Sin permiso `knowledge:create`
- `413 Payload Too Large` — Archivo supera 10MB

---

#### **DELETE** `/knowledge/documents/:sourceId`

Elimina una fuente de conocimiento, sus fragmentos de PostgreSQL, y sus vectores de Pinecone.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `knowledge:delete`

**Request**:
```http
DELETE /knowledge/documents/019405fa-0000-7000-8000-000000000001?sectorId=10000000-0000-0000-0000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
```

**Query Parameters**:
| Param | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `sectorId` | UUID | ✅ | ID del sector (para namespace de Pinecone) |

**Response**: `200 OK`
```json
{
  "sourceId": "019405fa-0000-7000-8000-000000000001",
  "fragmentsDeleted": 45,
  "vectorsDeleted": true
}
```

**Errores**:
- `400 Bad Request` — UUID inválido, sectorId faltante, source ya eliminada
- `404 Not Found` — Fuente no encontrada

---

### 5.4 Interaction — Chat RAG y Conversaciones

#### **POST** `/interaction/query`

Envía una consulta al asistente RAG. Busca fragmentos relevantes en Pinecone, construye un prompt con contexto, y genera una respuesta con Gemini 2.5 Flash.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `chat:read`  
**Rate Limit**: 30 requests/minuto

**Request**:
```http
POST /interaction/query
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
```

```json
{
  "sectorId": "10000000-0000-0000-0000-000000000001",
  "query": "¿Cuántos días de vacaciones tengo al año?",
  "conversationId": "019405fb-0000-7000-8000-000000000001",
  "maxResults": 5,
  "minSimilarity": 0.7
}
```

**Campos del body**:
| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `sectorId` | UUID | ✅ | Sector para filtrar conocimiento |
| `query` | String | ✅ | Pregunta del usuario (min 1 char) |
| `conversationId` | UUID | ❌ | ID de conversación existente (para continuidad) |
| `maxResults` | Number | ❌ | Máximo de fragmentos a recuperar (1-20, default: 5) |
| `minSimilarity` | Number | ❌ | Umbral mínimo de similitud (0-1, default: 0.7) |

> **Nota**: El `userId` se extrae del JWT session via `@CurrentUser('userId')` y NO se acepta en el body por razones de seguridad.

**Response**: `200 OK`
```json
{
  "response": "Según el Manual de Vacaciones 2026, los empleados tienen derecho a 15 días hábiles de vacaciones al año después del primer año de servicio...",
  "conversationId": "019405fb-0000-7000-8000-000000000001",
  "sources": [
    {
      "id": "019405fa-frag-7000-8000-000000000001",
      "content": "Los empleados tienen derecho a 15 días hábiles de vacaciones...",
      "sourceId": "019405fa-0000-7000-8000-000000000001",
      "similarity": 0.92,
      "metadata": { "position": 5 }
    }
  ],
  "timestamp": "2026-02-03T15:01:02Z",
  "evaluation": {
    "faithfulness": {
      "score": 0.92,
      "status": "PASS",
      "reasoning": "The response accurately reflects the vacation policy documented in the context."
    },
    "relevancy": {
      "score": 0.88,
      "status": "PASS",
      "reasoning": "The response directly answers the question about vacation days."
    }
  }
}
```

**Response DTO** (`QueryAssistantResponseDto`):
| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `response` | String | ✅ | Respuesta generada por el asistente |
| `conversationId` | UUID | ✅ | ID de la conversación (nueva o existente) |
| `sources` | SourceFragmentDto[] | ✅ | Fragmentos utilizados como contexto |
| `timestamp` | Date | ✅ | Timestamp de la respuesta |
| `evaluation` | EvaluationResultDto | ❌ | Scores de evaluación RAG (puede estar ausente si la evaluación falló) |

**EvaluationResultDto**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `faithfulness` | EvaluationScoreDto | Score de fidelidad al contexto documental |
| `relevancy` | EvaluationScoreDto | Score de relevancia a la pregunta del usuario |

**EvaluationScoreDto**:
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `score` | Number (0-1) | Puntuación numérica de la evaluación |
| `status` | Enum: `PASS`, `FAIL`, `UNKNOWN` | Estado de la evaluación |
| `reasoning` | String | Razonamiento breve del LLM juez |

**Errores**:
- `400 Bad Request` — Validación fallida (sectorId inválido, query vacío)
- `429 Too Many Requests` — Rate limit excedido (30/min)
- `500 Internal Server Error` — Error en RAG flow o Gemini API

---

#### **GET** `/interaction/conversations`

Lista las conversaciones del usuario autenticado con paginación.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `chat:read`  
**Rate Limit**: 50 requests/minuto

**Request**:
```http
GET /interaction/conversations?limit=10&offset=0&includeInactive=false
Authorization: Bearer <ACCESS_TOKEN>
```

**Query Parameters**:
| Param | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `limit` | Number | 10 | Máximo de conversaciones a retornar |
| `offset` | Number | 0 | Número de conversaciones a saltar |
| `includeInactive` | Boolean | false | Incluir conversaciones inactivas |

**Response**: `200 OK`
```json
{
  "conversations": [
    {
      "id": "019405fb-0000-7000-8000-000000000001",
      "title": "Consulta sobre vacaciones",
      "messageCount": 4,
      "lastMessage": "¿Cuántos días de vacaciones tengo?",
      "createdAt": "2026-02-03T15:00:00Z",
      "updatedAt": "2026-02-03T15:01:02Z"
    }
  ],
  "total": 1,
  "count": 1,
  "offset": 0
}
```

---

#### **GET** `/interaction/conversations/:id`

Obtiene el detalle de una conversación con todos sus mensajes.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `chat:read`  
**Rate Limit**: 60 requests/minuto

**Request**:
```http
GET /interaction/conversations/019405fb-0000-7000-8000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "id": "019405fb-0000-7000-8000-000000000001",
  "title": "Consulta sobre vacaciones",
  "messages": [
    {
      "id": "019405fc-0001-7000-8000-000000000001",
      "role": "user",
      "content": "¿Cuántos días de vacaciones tengo al año?",
      "createdAt": "2026-02-03T15:01:00Z"
    },
    {
      "id": "019405fc-0002-7000-8000-000000000002",
      "role": "assistant",
      "content": "Según el Manual de Vacaciones 2026...",
      "metadata": {
        "model": "gemini-2.5-flash",
        "evaluation": {
          "faithfulness": { "score": 0.92, "status": "PASS", "reasoning": "..." },
          "relevancy": { "score": 0.88, "status": "PASS", "reasoning": "..." }
        }
      },
      "createdAt": "2026-02-03T15:01:02Z"
    }
  ],
  "messageCount": 2,
  "createdAt": "2026-02-03T15:00:00Z",
  "updatedAt": "2026-02-03T15:01:02Z"
}
```

**Errores**:
- `404 Not Found` — Conversación no encontrada o no pertenece al usuario

---

#### **DELETE** `/interaction/conversations/:id`

Elimina (soft delete) una conversación. Solo puede eliminar conversaciones propias.

**Autenticación**: JWT Bearer  
**Permiso requerido**: `chat:read`  
**Rate Limit**: 20 requests/minuto

**Request**:
```http
DELETE /interaction/conversations/019405fb-0000-7000-8000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `204 No Content`

**Errores**:
- `404 Not Found` — Conversación no encontrada o no pertenece al usuario

---

## 6. Códigos de Error

### Estructura de Error NestJS

```json
{
  "statusCode": 400,
  "message": ["sectorId must be a UUID", "query should not be empty"],
  "error": "Bad Request"
}
```

### Códigos HTTP

| HTTP | Descripción |
|------|-------------|
| 200 | Operación exitosa |
| 201 | Recurso creado exitosamente |
| 204 | Operación exitosa sin contenido |
| 400 | Datos inválidos en request |
| 401 | Token ausente/inválido |
| 403 | Sin permisos para recurso |
| 404 | Recurso no existe |
| 413 | Archivo supera 10 MB |
| 429 | Rate limit excedido |
| 500 | Error inesperado |

---

## 7. Headers de Seguridad

### Request Headers

```http
Authorization: Bearer <ACCESS_TOKEN>        # JWT de Auth0
Content-Type: application/json               # o multipart/form-data
X-Internal-API-Key: <KEY>                    # Solo para /users/sync
```

### Response Headers (Helmet)

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0
Content-Security-Policy: default-src 'self'
```

---

## 8. Rate Limiting

Implementado con `@nestjs/throttler`.

| Endpoint | Límite | Ventana |
|----------|--------|---------|
| `POST /interaction/query` | 30 req | 1 min |
| `GET /interaction/conversations` | 50 req | 1 min |
| `GET /interaction/conversations/:id` | 60 req | 1 min |
| `DELETE /interaction/conversations/:id` | 20 req | 1 min |
| Todos los demás | Default global | — |

**Response cuando se excede**:
```json
{
  "statusCode": 429,
  "message": "Too many requests. Please try again later.",
  "error": "Too Many Requests"
}
```

---

## 9. Permisos del Sistema

| Permiso | Recurso | Acción | Endpoints |
|---------|---------|--------|-----------|
| `knowledge:create` | knowledge | create | `POST /knowledge/documents/upload` |
| `knowledge:delete` | knowledge | delete | `DELETE /knowledge/documents/:sourceId` |
| `chat:read` | chat | read | Todos los `/interaction/*` |
| `profile:read` | profile | read | `GET /users/profile` |
| `admin:manage_sectors` | admin | manage_sectors | (Post-MVP) |
| `admin:manage_roles` | admin | manage_roles | (Post-MVP) |
| `admin:manage_users` | admin | manage_users | (Post-MVP) |

---

## 10. Cambios vs Diseño Original

| Aspecto | Diseño Original | Implementación Actual |
|---------|----------------|----------------------|
| URL versioning | `/api/v1/...` | Sin versión en URL |
| Auth endpoints | `/auth/login`, `/auth/callback`, `/auth/logout`, `/auth/me` | **No existen** (auth manejada por NextAuth.js en frontend) |
| Sectors endpoints | `/sectors`, `/sectors/:slug` | **No existen** (sectores como UUID strings) |
| Knowledge upload | `POST /knowledge/sources` | `POST /knowledge/documents/upload` |
| Knowledge list | `GET /knowledge/sources` | **No implementado** |
| Knowledge detail | `GET /knowledge/sources/:id` | **No implementado** |
| Knowledge delete | `DELETE /knowledge/sources/:id` | `DELETE /knowledge/documents/:sourceId?sectorId=` |
| Chat create | `POST /chat/conversations` | **No existe** (creación implícita en `/interaction/query`) |
| Chat query | `POST /chat/conversations/:id/messages` | `POST /interaction/query` (con conversationId opcional) |
| Chat history | `GET /chat/conversations/:id/messages` | `GET /interaction/conversations/:id` |
| Chat list | `GET /chat/conversations` | `GET /interaction/conversations` |
| Chat update | `PATCH /chat/conversations/:id` | **No implementado** |
| User sync | `POST /auth/sync` | `POST /users/sync` (con `X-Internal-API-Key`) |
| User profile | `GET /auth/me` | `GET /users/profile` |
| Response wrapper | `{ success, data, error, timestamp }` | NestJS responses directas (sin wrapper custom) |
| Pagination | `page`/`limit` con `meta` | `offset`/`limit` con `total`/`count` |
| Error format | Custom `ApiError` | NestJS standard `{ statusCode, message, error }` |

---

## 11. Documentación Interactiva

### Swagger/OpenAPI

```bash
# Acceder a la documentación interactiva
GET http://localhost:3001/api/docs
```

La documentación se genera automáticamente desde los decoradores `@ApiTags`, `@ApiOperation`, `@ApiResponse`, `@ApiProperty`, etc., en cada controller y DTO.

---

## Resumen

✅ **Total de endpoints**: 9 implementados  
✅ **DTOs compartidos**: `context-ai-shared` con enums, tipos, DTOs  
✅ **Autenticación**: JWT (Auth0 JWKS) + Internal API Key (server-to-server)  
✅ **Autorización**: RBAC con permisos granulares  
✅ **Seguridad**: Helmet, Rate Limiting, CORS, Input validation  
✅ **Documentación**: Swagger/OpenAPI auto-generada  
✅ **Testing**: Jest + Supertest para tests de contratos
