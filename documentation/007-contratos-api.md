# Contratos de API - Context.ai
## Documentación de Endpoints REST y DTOs Compartidos

---

## 1. Visión General

Context.ai expone una **API RESTful** con endpoints versionados para el MVP (UC2: Ingesta + UC5: Chat RAG).

### Arquitectura de Comunicación

```
┌─────────────────────┐
│  context-ai-front   │
│     (Next.js)       │
└──────────┬──────────┘
           │ HTTP + JWT
           │ Authorization: Bearer <TOKEN>
           │ Cookie: session (HttpOnly)
           ▼
┌─────────────────────┐
│  context-ai-api     │
│    (NestJS)         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PostgreSQL         │
│  + pgvector         │
└─────────────────────┘

┌─────────────────────┐
│ context-ai-shared   │
│  (DTOs TypeScript)  │ ← Importado por front y back
└─────────────────────┘
```

---

## 2. Configuración Base

### Base URL

```
Development:  http://localhost:3001/api/v1
Production:   https://api.context.ai/api/v1
```

### Versionado

- **Estrategia**: URL Path versioning (`/api/v1/...`)
- **Versión actual**: `v1`
- **Breaking changes**: Nueva versión (v2, v3, etc.)

### Autenticación

Todos los endpoints (excepto `/health` y `/auth/*`) requieren autenticación:

```http
Authorization: Bearer <ACCESS_TOKEN>
Cookie: session=<ENCRYPTED_SESSION>; HttpOnly; Secure; SameSite=Strict
```

---

## 3. Módulos de la API

| Módulo | Prefijo | Descripción | MVP |
|--------|---------|-------------|-----|
| Health | `/health` | Status de la API | ✅ |
| Auth | `/auth` | Autenticación Auth0 | ✅ |
| Users | `/users` | Gestión de usuarios | ✅ |
| Sectors | `/sectors` | Sectores organizacionales | ✅ |
| Knowledge | `/knowledge` | Ingesta documentos (UC2) | ✅ |
| Chat | `/chat` | Conversaciones IA (UC5) | ✅ |
| Admin | `/admin` | Gestión roles/permisos | 🔵 Post-MVP |

---

## 4. DTOs Compartidos (context-ai-shared)

### Estructura del Repositorio `context-ai-shared`

```
context-ai-shared/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts                    # Export barrel
│   ├── types/
│   │   ├── common.types.ts         # UUID, Timestamp, etc.
│   │   ├── auth.types.ts           # Roles, Permissions
│   │   └── enums.ts                # Enums compartidos
│   ├── dtos/
│   │   ├── auth/
│   │   │   ├── login.dto.ts
│   │   │   └── user.dto.ts
│   │   ├── sectors/
│   │   │   └── sector.dto.ts
│   │   ├── knowledge/
│   │   │   ├── source.dto.ts
│   │   │   └── upload.dto.ts
│   │   └── chat/
│   │       ├── conversation.dto.ts
│   │       ├── message.dto.ts
│   │       └── query.dto.ts
│   └── validators/
│       └── custom-validators.ts    # Validadores reutilizables
└── README.md
```

### Instalación en Proyectos

```bash
# En context-ai-api
pnpm add file:../context-ai-shared

# En context-ai-front
pnpm add file:../context-ai-shared
```

---

## 5. Tipos Comunes

### `src/types/common.types.ts`

```typescript
// UUIDs tipados por entidad
export type UUID = string; // UUID v7
export type UserID = UUID;
export type SectorID = UUID;
export type SourceID = UUID;
export type ConversationID = UUID;
export type MessageID = UUID;

// Timestamps
export type ISOTimestamp = string; // ISO 8601

// Paginación
export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// Respuesta genérica de API
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: ApiError;
  timestamp: ISOTimestamp;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, any>;
}
```

---

### `src/types/enums.ts`

```typescript
// Roles del sistema
export enum Role {
  ADMIN = 'ADMIN',
  USER = 'USER',
  CONTENT_MANAGER = 'CONTENT_MANAGER',
}

// Permisos granulares
export enum Permission {
  KNOWLEDGE_READ = 'knowledge:read',
  KNOWLEDGE_WRITE = 'knowledge:write',
  KNOWLEDGE_DELETE = 'knowledge:delete',
  CHAT_QUERY = 'chat:query',
  ADMIN_MANAGE_SECTORS = 'admin:manage_sectors',
  ADMIN_MANAGE_ROLES = 'admin:manage_roles',
  ADMIN_MANAGE_USERS = 'admin:manage_users',
}

// Tipos de fuentes de conocimiento
export enum SourceType {
  PDF = 'PDF',
  MARKDOWN = 'MARKDOWN',
  WEB_LINK = 'WEB_LINK',
}

// Estados de procesamiento
export enum SourceStatus {
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  DELETED = 'deleted',
}

// Roles en mensajes
export enum MessageRole {
  USER = 'USER',
  ASSISTANT = 'ASSISTANT',
  SYSTEM = 'SYSTEM',
}

// Estados de conversación
export enum ConversationStatus {
  ACTIVE = 'active',
  ARCHIVED = 'archived',
  DELETED = 'deleted',
}
```

---

### `src/types/auth.types.ts`

```typescript
import { Role, Permission } from './enums';
import { UserID, SectorID, ISOTimestamp } from './common.types';

// Payload del JWT
export interface JWTPayload {
  sub: UserID;              // User ID
  email: string;
  name: string;
  roles: UserRole[];
  iat: number;              // Issued at
  exp: number;              // Expiration
}

// Rol asignado a usuario
export interface UserRole {
  roleId: string;
  roleName: Role;
  permissions: Permission[];
  sectorId?: SectorID;      // null = global
  expiresAt?: ISOTimestamp; // null = permanent
}

// Contexto de autorización
export interface AuthContext {
  userId: UserID;
  email: string;
  roles: UserRole[];
  hasPermission: (permission: Permission, sectorId?: SectorID) => boolean;
}
```

---

## 6. Endpoints de Autenticación

### **POST** `/auth/login`

Redirige a Auth0 para login social (Google OAuth2).

**Request**:
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "redirectUri": "http://localhost:3000/callback"
}
```

**Response**: `302 Redirect`
```http
Location: https://<AUTH0_DOMAIN>/authorize?...
```

---

### **GET** `/auth/callback`

Callback de Auth0 después de autenticación exitosa.

**Query Params**:
```
?code=<AUTHORIZATION_CODE>&state=<STATE>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "019405f8-6d84-7000-8000-123456789abc",
      "email": "usuario@example.com",
      "name": "Juan Pérez",
      "isActive": true,
      "createdAt": "2026-01-15T10:30:00Z",
      "lastLoginAt": "2026-02-03T14:22:00Z"
    },
    "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600
  },
  "timestamp": "2026-02-03T14:22:00Z"
}
```

**Cookies establecidas**:
```http
Set-Cookie: session=<ENCRYPTED_DATA>; HttpOnly; Secure; SameSite=Strict; Max-Age=3600
```

**DTO**: `src/dtos/auth/login-response.dto.ts`
```typescript
import { UserID, ISOTimestamp } from '../../types/common.types';

export interface LoginResponseDto {
  user: UserDto;
  accessToken: string;
  expiresIn: number; // seconds
}

export interface UserDto {
  id: UserID;
  email: string;
  name: string;
  isActive: boolean;
  createdAt: ISOTimestamp;
  lastLoginAt?: ISOTimestamp;
}
```

---

### **POST** `/auth/logout`

Cierra sesión del usuario.

**Request**:
```http
POST /api/v1/auth/logout
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  },
  "timestamp": "2026-02-03T14:30:00Z"
}
```

**Cookies borradas**:
```http
Set-Cookie: session=; Max-Age=0
```

---

### **GET** `/auth/me`

Obtiene información del usuario autenticado.

**Request**:
```http
GET /api/v1/auth/me
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "019405f8-6d84-7000-8000-123456789abc",
    "email": "usuario@example.com",
    "name": "Juan Pérez",
    "isActive": true,
    "roles": [
      {
        "roleId": "00000000-0000-0000-0000-000000000002",
        "roleName": "USER",
        "permissions": ["knowledge:read", "chat:query"],
        "sectorId": "10000000-0000-0000-0000-000000000001",
        "expiresAt": null
      }
    ],
    "createdAt": "2026-01-15T10:30:00Z",
    "lastLoginAt": "2026-02-03T14:22:00Z"
  },
  "timestamp": "2026-02-03T14:25:00Z"
}
```

**DTO**: `src/dtos/auth/user.dto.ts`
```typescript
import { UserID, ISOTimestamp } from '../../types/common.types';
import { UserRole } from '../../types/auth.types';

export interface UserProfileDto {
  id: UserID;
  email: string;
  name: string;
  isActive: boolean;
  roles: UserRole[];
  createdAt: ISOTimestamp;
  lastLoginAt?: ISOTimestamp;
}
```

---

## 7. Endpoints de Sectores

### **GET** `/sectors`

Lista todos los sectores activos.

**Request**:
```http
GET /api/v1/sectors
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "10000000-0000-0000-0000-000000000001",
      "name": "Recursos Humanos",
      "description": "Documentación de políticas, procedimientos y beneficios",
      "slug": "rrhh",
      "color": "#10B981",
      "icon": "users",
      "isActive": true,
      "createdAt": "2026-01-10T08:00:00Z"
    },
    {
      "id": "10000000-0000-0000-0000-000000000002",
      "name": "Tecnología",
      "description": "Documentación técnica y procedimientos de desarrollo",
      "slug": "tech",
      "color": "#3B82F6",
      "icon": "code",
      "isActive": true,
      "createdAt": "2026-01-10T08:00:00Z"
    }
  ],
  "timestamp": "2026-02-03T14:30:00Z"
}
```

**DTO**: `src/dtos/sectors/sector.dto.ts`
```typescript
import { SectorID, ISOTimestamp } from '../../types/common.types';

export interface SectorDto {
  id: SectorID;
  name: string;
  description: string;
  slug: string;
  color: string;    // Hex color
  icon: string;     // Icon name
  isActive: boolean;
  createdAt: ISOTimestamp;
}
```

---

### **GET** `/sectors/:slug`

Obtiene detalles de un sector por slug.

**Request**:
```http
GET /api/v1/sectors/rrhh
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK` (igual que el objeto individual arriba)

---

## 8. Endpoints de Ingesta (UC2)

### **POST** `/knowledge/sources`

Sube un documento para procesamiento (PDF o Markdown).

**Request**: `multipart/form-data`
```http
POST /api/v1/knowledge/sources
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: multipart/form-data

------WebKitFormBoundary
Content-Disposition: form-data; name="sectorId"

10000000-0000-0000-0000-000000000001
------WebKitFormBoundary
Content-Disposition: form-data; name="title"

Manual de Vacaciones 2026
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="manual-vacaciones.pdf"
Content-Type: application/pdf

<BINARY_DATA>
------WebKitFormBoundary--
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "019405fa-0000-7000-8000-000000000001",
    "sectorId": "10000000-0000-0000-0000-000000000001",
    "title": "Manual de Vacaciones 2026",
    "sourceType": "PDF",
    "fileName": "manual-vacaciones.pdf",
    "fileSize": 2457600,
    "mimeType": "application/pdf",
    "status": "processing",
    "uploadedBy": "019405f8-6d84-7000-8000-123456789abc",
    "createdAt": "2026-02-03T14:35:00Z"
  },
  "timestamp": "2026-02-03T14:35:00Z"
}
```

**Validaciones**:
- Tamaño máximo: 10 MB (MVP)
- Tipos permitidos: `application/pdf`, `text/markdown`
- Título: 3-255 caracteres
- Sanitización de texto para prevenir prompt injection

**DTO**: `src/dtos/knowledge/upload-source.dto.ts`
```typescript
import { SectorID } from '../../types/common.types';
import { SourceType } from '../../types/enums';

export interface UploadSourceDto {
  sectorId: SectorID;
  title: string;
  file: File | Buffer; // File en frontend, Buffer en backend
}

export interface UploadSourceResponseDto {
  id: string;
  sectorId: SectorID;
  title: string;
  sourceType: SourceType;
  fileName: string;
  fileSize: number;
  mimeType: string;
  status: SourceStatus;
  uploadedBy: UserID;
  createdAt: ISOTimestamp;
}
```

---

### **GET** `/knowledge/sources`

Lista documentos de un sector con paginación.

**Request**:
```http
GET /api/v1/knowledge/sources?sectorId=<UUID>&page=1&limit=20&sortBy=createdAt&sortOrder=desc
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "019405fa-0000-7000-8000-000000000001",
      "sectorId": "10000000-0000-0000-0000-000000000001",
      "title": "Manual de Vacaciones 2026",
      "sourceType": "PDF",
      "fileName": "manual-vacaciones.pdf",
      "fileSize": 2457600,
      "status": "completed",
      "fragmentCount": 45,
      "totalTokens": 12500,
      "uploadedBy": {
        "id": "019405f8-6d84-7000-8000-123456789abc",
        "name": "Juan Pérez"
      },
      "createdAt": "2026-02-03T14:35:00Z",
      "indexedAt": "2026-02-03T14:37:22Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  },
  "timestamp": "2026-02-03T14:40:00Z"
}
```

**DTO**: `src/dtos/knowledge/source.dto.ts`
```typescript
import { SourceID, UserID, SectorID, ISOTimestamp } from '../../types/common.types';
import { SourceType, SourceStatus } from '../../types/enums';

export interface KnowledgeSourceDto {
  id: SourceID;
  sectorId: SectorID;
  title: string;
  sourceType: SourceType;
  fileName?: string;
  fileSize?: number;
  status: SourceStatus;
  fragmentCount: number;
  totalTokens: number;
  uploadedBy: {
    id: UserID;
    name: string;
  };
  createdAt: ISOTimestamp;
  indexedAt?: ISOTimestamp;
}
```

---

### **GET** `/knowledge/sources/:id`

Obtiene detalles de un documento específico.

**Request**:
```http
GET /api/v1/knowledge/sources/019405fa-0000-7000-8000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK` (igual que el objeto individual arriba, con más metadatos)
```json
{
  "success": true,
  "data": {
    "id": "019405fa-0000-7000-8000-000000000001",
    "sectorId": "10000000-0000-0000-0000-000000000001",
    "title": "Manual de Vacaciones 2026",
    "sourceType": "PDF",
    "fileName": "manual-vacaciones.pdf",
    "fileSize": 2457600,
    "mimeType": "application/pdf",
    "contentHash": "sha256:a1b2c3...",
    "version": "v1_a1b2c3",
    "status": "completed",
    "fragmentCount": 45,
    "totalTokens": 12500,
    "metadata": {
      "pages": 50,
      "author": "RRHH Team",
      "createdDate": "2024-01-15"
    },
    "uploadedBy": {
      "id": "019405f8-6d84-7000-8000-123456789abc",
      "name": "Juan Pérez"
    },
    "createdAt": "2026-02-03T14:35:00Z",
    "updatedAt": "2026-02-03T14:37:22Z",
    "indexedAt": "2026-02-03T14:37:22Z"
  },
  "timestamp": "2026-02-03T14:45:00Z"
}
```

---

### **DELETE** `/knowledge/sources/:id`

Elimina un documento (soft delete, marca status='deleted' y borra embeddings).

**Request**:
```http
DELETE /api/v1/knowledge/sources/019405fa-0000-7000-8000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "message": "Document deleted successfully",
    "id": "019405fa-0000-7000-8000-000000000001",
    "fragmentsDeleted": 45
  },
  "timestamp": "2026-02-03T14:50:00Z"
}
```

**Permisos requeridos**: `knowledge:delete`

---

## 9. Endpoints de Chat (UC5)

### **POST** `/chat/conversations`

Crea una nueva conversación.

**Request**:
```http
POST /api/v1/chat/conversations
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json

{
  "sectorId": "10000000-0000-0000-0000-000000000001",
  "title": "Consulta sobre vacaciones"
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "019405fb-0000-7000-8000-000000000001",
    "userId": "019405f8-6d84-7000-8000-123456789abc",
    "sectorId": "10000000-0000-0000-0000-000000000001",
    "title": "Consulta sobre vacaciones",
    "status": "active",
    "messageCount": 0,
    "startedAt": "2026-02-03T15:00:00Z",
    "lastMessageAt": "2026-02-03T15:00:00Z"
  },
  "timestamp": "2026-02-03T15:00:00Z"
}
```

**DTO**: `src/dtos/chat/conversation.dto.ts`
```typescript
import { ConversationID, UserID, SectorID, ISOTimestamp } from '../../types/common.types';
import { ConversationStatus } from '../../types/enums';

export interface CreateConversationDto {
  sectorId: SectorID;
  title?: string; // Opcional, se genera del primer mensaje si no se provee
}

export interface ConversationDto {
  id: ConversationID;
  userId: UserID;
  sectorId: SectorID;
  title?: string;
  status: ConversationStatus;
  messageCount: number;
  startedAt: ISOTimestamp;
  lastMessageAt: ISOTimestamp;
  endedAt?: ISOTimestamp;
}
```

---

### **POST** `/chat/conversations/:id/messages`

Envía un mensaje (pregunta del usuario) y recibe respuesta del asistente IA.

**Request**:
```http
POST /api/v1/chat/conversations/019405fb-0000-7000-8000-000000000001/messages
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json

{
  "content": "¿Cuántos días de vacaciones tengo al año?"
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "userMessage": {
      "id": "019405fc-0001-7000-8000-000000000001",
      "conversationId": "019405fb-0000-7000-8000-000000000001",
      "role": "USER",
      "content": "¿Cuántos días de vacaciones tengo al año?",
      "createdAt": "2026-02-03T15:01:00Z"
    },
    "assistantMessage": {
      "id": "019405fc-0002-7000-8000-000000000002",
      "conversationId": "019405fb-0000-7000-8000-000000000001",
      "role": "ASSISTANT",
      "content": "Según el Manual de Vacaciones 2026, los empleados tienen derecho a 15 días hábiles de vacaciones al año después del primer año de servicio. Durante el primer año, se acumulan proporcionalmente (1.25 días por mes trabajado).",
      "sourcesUsed": [
        {
          "fragmentId": "019405fa-frag-7000-8000-000000000001",
          "sourceId": "019405fa-0000-7000-8000-000000000001",
          "sourceTitle": "Manual de Vacaciones 2026",
          "relevanceScore": 0.89,
          "excerpt": "Los empleados tienen derecho a 15 días hábiles de vacaciones al año después del primer año de servicio..."
        }
      ],
      "metadata": {
        "model": "gemini-1.5-pro",
        "latencyMs": 2350,
        "tokensUsed": 1240,
        "faithfulnessScore": 0.87,
        "relevancyScore": 0.92,
        "promptVersion": "v1.2",
        "fragmentsRetrieved": 5
      },
      "createdAt": "2026-02-03T15:01:02Z"
    }
  },
  "timestamp": "2026-02-03T15:01:02Z"
}
```

**DTO**: `src/dtos/chat/message.dto.ts`
```typescript
import { MessageID, ConversationID, SourceID, ISOTimestamp } from '../../types/common.types';
import { MessageRole } from '../../types/enums';

export interface SendMessageDto {
  content: string; // 1-2000 caracteres
}

export interface MessageDto {
  id: MessageID;
  conversationId: ConversationID;
  role: MessageRole;
  content: string;
  sourcesUsed?: SourceReference[];
  metadata?: MessageMetadata;
  createdAt: ISOTimestamp;
}

export interface SourceReference {
  fragmentId: string;
  sourceId: SourceID;
  sourceTitle: string;
  relevanceScore: number; // 0-1
  excerpt: string;        // Fragmento citado
}

export interface MessageMetadata {
  model: string;
  latencyMs: number;
  tokensUsed: number;
  faithfulnessScore?: number;  // Genkit Evaluator
  relevancyScore?: number;     // Genkit Evaluator
  promptVersion: string;
  fragmentsRetrieved: number;
}

export interface SendMessageResponseDto {
  userMessage: MessageDto;
  assistantMessage: MessageDto;
}
```

**Validaciones**:
- Contenido: 1-2000 caracteres
- Sanitización de texto (prompt injection prevention)
- Rate limit: 10 mensajes/minuto por usuario

---

### **GET** `/chat/conversations/:id/messages`

Obtiene el historial de mensajes de una conversación.

**Request**:
```http
GET /api/v1/chat/conversations/019405fb-0000-7000-8000-000000000001/messages?page=1&limit=50
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "019405fc-0001-7000-8000-000000000001",
      "conversationId": "019405fb-0000-7000-8000-000000000001",
      "role": "USER",
      "content": "¿Cuántos días de vacaciones tengo al año?",
      "createdAt": "2026-02-03T15:01:00Z"
    },
    {
      "id": "019405fc-0002-7000-8000-000000000002",
      "conversationId": "019405fb-0000-7000-8000-000000000001",
      "role": "ASSISTANT",
      "content": "Según el Manual de Vacaciones 2026...",
      "sourcesUsed": [...],
      "metadata": {...},
      "createdAt": "2026-02-03T15:01:02Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 2,
    "totalPages": 1
  },
  "timestamp": "2026-02-03T15:05:00Z"
}
```

---

### **GET** `/chat/conversations`

Lista conversaciones del usuario autenticado.

**Request**:
```http
GET /api/v1/chat/conversations?sectorId=<UUID>&status=active&page=1&limit=20
Authorization: Bearer <ACCESS_TOKEN>
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "019405fb-0000-7000-8000-000000000001",
      "userId": "019405f8-6d84-7000-8000-123456789abc",
      "sectorId": "10000000-0000-0000-0000-000000000001",
      "title": "Consulta sobre vacaciones",
      "status": "active",
      "messageCount": 2,
      "startedAt": "2026-02-03T15:00:00Z",
      "lastMessageAt": "2026-02-03T15:01:02Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  },
  "timestamp": "2026-02-03T15:10:00Z"
}
```

---

### **PATCH** `/chat/conversations/:id`

Actualiza una conversación (cambiar título o archivar).

**Request**:
```http
PATCH /api/v1/chat/conversations/019405fb-0000-7000-8000-000000000001
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json

{
  "status": "archived"
}
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "019405fb-0000-7000-8000-000000000001",
    "status": "archived",
    "endedAt": "2026-02-03T15:15:00Z"
  },
  "timestamp": "2026-02-03T15:15:00Z"
}
```

**DTO**: `src/dtos/chat/update-conversation.dto.ts`
```typescript
import { ConversationStatus } from '../../types/enums';

export interface UpdateConversationDto {
  title?: string;
  status?: ConversationStatus; // active, archived, deleted
}
```

---

## 10. Endpoint de Health Check

### **GET** `/health`

Verifica el estado de la API y sus dependencias.

**Request**:
```http
GET /api/v1/health
```

**Response**: `200 OK`
```json
{
  "status": "healthy",
  "timestamp": "2026-02-03T15:20:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": "healthy",
    "pgvector": "healthy",
    "genkit": "healthy"
  },
  "uptime": 86400
}
```

---

## 11. Códigos de Error

### Estructura de Error

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired access token",
    "details": {
      "reason": "token_expired",
      "expiredAt": "2026-02-03T14:00:00Z"
    }
  },
  "timestamp": "2026-02-03T15:00:00Z"
}
```

### Códigos HTTP

| HTTP | Code | Descripción |
|------|------|-------------|
| 400 | `BAD_REQUEST` | Datos inválidos en request |
| 401 | `UNAUTHORIZED` | Token ausente/inválido |
| 403 | `FORBIDDEN` | Sin permisos para recurso |
| 404 | `NOT_FOUND` | Recurso no existe |
| 409 | `CONFLICT` | Conflicto (ej: documento duplicado) |
| 413 | `PAYLOAD_TOO_LARGE` | Archivo supera 10 MB |
| 422 | `UNPROCESSABLE_ENTITY` | Validación falló |
| 429 | `TOO_MANY_REQUESTS` | Rate limit excedido |
| 500 | `INTERNAL_SERVER_ERROR` | Error inesperado |
| 503 | `SERVICE_UNAVAILABLE` | Servicio temporalmente no disponible |

### Códigos de Negocio

| Code | HTTP | Descripción |
|------|------|-------------|
| `INVALID_FILE_TYPE` | 400 | Tipo de archivo no soportado |
| `DOCUMENT_PROCESSING_FAILED` | 422 | Error al procesar documento |
| `SECTOR_NOT_FOUND` | 404 | Sector no existe |
| `CONVERSATION_NOT_FOUND` | 404 | Conversación no existe |
| `INSUFFICIENT_PERMISSIONS` | 403 | Usuario sin permisos |
| `PROMPT_INJECTION_DETECTED` | 422 | Texto sanitizado rechazado |
| `RAG_QUERY_FAILED` | 500 | Error en búsqueda vectorial |
| `AI_GENERATION_FAILED` | 500 | Error al generar respuesta IA |

**DTO**: `src/types/common.types.ts` (ya definido arriba)

---

## 12. Headers de Seguridad

### Request Headers Obligatorios

```http
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
X-Request-ID: <UUID>  # Para trazabilidad
```

### Response Headers

```http
X-Request-ID: <UUID>
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 58
X-RateLimit-Reset: 1643900400
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

---

## 13. Rate Limiting

| Endpoint | Límite | Ventana |
|----------|--------|---------|
| `/auth/*` | 5 req | 1 min |
| `/chat/*/messages` (POST) | 10 req | 1 min |
| `/knowledge/sources` (POST) | 5 req | 5 min |
| Todos los demás | 60 req | 1 min |

**Response cuando se excede**:
```json
{
  "success": false,
  "error": {
    "code": "TOO_MANY_REQUESTS",
    "message": "Rate limit exceeded. Try again in 45 seconds.",
    "details": {
      "retryAfter": 45,
      "limit": 10,
      "window": "1 minute"
    }
  },
  "timestamp": "2026-02-03T15:25:00Z"
}
```

---

## 14. Paginación

### Query Parameters

```
?page=1           # Número de página (1-indexed)
?limit=20         # Items por página (1-100, default 20)
?sortBy=createdAt # Campo para ordenar
?sortOrder=desc   # asc | desc
```

### Response Meta

```json
{
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 157,
    "totalPages": 8,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

**DTO**: Ya definido en `src/types/common.types.ts`

---

## 15. Versionado de DTOs

### Estrategia

- **Retrocompatibilidad**: Nuevos campos opcionales
- **Breaking changes**: Nueva versión de DTO con sufijo (ej: `MessageDtoV2`)
- **Deprecación**: Marcar con `@deprecated` JSDoc

### Ejemplo

```typescript
/**
 * @deprecated Use MessageDtoV2 instead. Will be removed in v2.0.0
 */
export interface MessageDto {
  // ...
}

export interface MessageDtoV2 extends Omit<MessageDto, 'metadata'> {
  metadata: EnhancedMetadata; // Nuevo tipo
  evaluations: Evaluation[];  // Campo nuevo
}
```

---

## 16. Validación de DTOs

### Backend (NestJS)

```typescript
import { IsString, IsUUID, MinLength, MaxLength } from 'class-validator';
import { SendMessageDto } from '@context-ai/shared';

export class SendMessageRequestDto implements SendMessageDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  content: string;
}
```

### Frontend (Zod)

```typescript
import { z } from 'zod';
import { SendMessageDto } from '@context-ai/shared';

export const sendMessageSchema = z.object({
  content: z.string().min(1).max(2000),
}) satisfies z.ZodType<SendMessageDto>;
```

---

## 17. Testing de Contratos

### Estrategia

1. **Unit tests**: Validación de DTOs
2. **Integration tests**: E2E con supertest
3. **Contract tests**: Pact/Swagger validation

### Ejemplo (Vitest + Supertest)

```typescript
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';

describe('POST /chat/conversations/:id/messages', () => {
  it('should send message and receive AI response', async () => {
    const response = await request(app)
      .post('/api/v1/chat/conversations/test-id/messages')
      .set('Authorization', `Bearer ${testToken}`)
      .send({ content: 'Test question' })
      .expect(201);

    expect(response.body.success).toBe(true);
    expect(response.body.data.userMessage.role).toBe('USER');
    expect(response.body.data.assistantMessage.role).toBe('ASSISTANT');
    expect(response.body.data.assistantMessage.sourcesUsed).toBeDefined();
  });
});
```

---

## 18. Documentación Interactiva

### Swagger/OpenAPI

```bash
# Generar especificación OpenAPI
pnpm run generate:openapi

# Servir documentación interactiva
GET http://localhost:3001/api/docs
```

### Postman Collection

```bash
# Exportar colección
pnpm run export:postman
# Output: context-ai.postman_collection.json
```

---

## Resumen

✅ **Total de endpoints MVP**: 15  
✅ **DTOs compartidos**: 12+  
✅ **Autenticación**: Auth0 + JWT  
✅ **Seguridad**: CORS, Rate Limiting, Helmet, Text Sanitization  
✅ **Versionado**: URL Path (`/api/v1/`)  
✅ **Paginación**: Estándar con meta  
✅ **Errores**: Códigos consistentes  
✅ **Testing**: Contratos validados con TDD  

---

**Documento elaborado para el desarrollo del MVP de Context.ai siguiendo RESTful best practices y arquitectura multi-repo.**

