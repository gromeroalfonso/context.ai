# Definición del MVP - Context.ai
## Producto Mínimo Viable: Sistema RAG con Chat Inteligente

---

## 1. ¿Qué es el MVP?

El **MVP (Minimum Viable Product)** de Context.ai es la versión más simple del producto que permite validar la hipótesis principal: **un sistema RAG puede reducir significativamente el tiempo de onboarding y resolver dudas operativas sin intervención humana constante**.

### Hipótesis a Validar

1. Los empleados pueden obtener respuestas precisas consultando documentación mediante IA
2. El sistema RAG reduce al menos un 50% las consultas a compañeros veteranos
3. Las respuestas generadas son consideradas útiles (rating ≥ 4/5) en al menos el 70% de los casos
4. El aislamiento por sectores previene fugas de información entre departamentos

---

## 2. Alcance del MVP

### 2.1 Funcionalidades Incluidas ✅

#### UC2: Ingesta de Documentación (Core)
**Como** administrador de contenido  
**Quiero** subir documentos PDF y Markdown a un sector específico  
**Para que** el sistema los procese y los haga disponibles para consultas

**Criterios de aceptación**:
- ✅ Puedo subir archivos PDF (máximo 10MB)
- ✅ Puedo subir archivos Markdown (.md)
- ✅ Especifico a qué sector pertenece el documento
- ✅ El sistema procesa el documento automáticamente (parsing, chunking, embeddings)
- ✅ **El contenido pasa validación de sanitización anti-prompt-injection**
- ✅ Veo confirmación de que el documento fue indexado correctamente
- ✅ El procesamiento completa en menos de 2 minutos para un PDF de 50 páginas
- ✅ Los documentos con contenido malicioso son rechazados con mensaje claro

**Entregables técnicos**:
- API endpoint: `POST /api/knowledge/sources`
- Parsing de PDF con `pdf-parse`
- **`TextSanitizationService`** - Validación y limpieza de contenido:
  - Detección de patrones de prompt injection
  - Limpieza de caracteres especiales y escape sequences
  - Validación de contenido sospechoso antes de indexar
- Chunking de 500 tokens con overlap de 50
- Generación de embeddings con Genkit
- Almacenamiento en PostgreSQL + pgvector
- Tests unitarios y de integración con TDD
- **Tests específicos de seguridad** para prompt injection

---

#### UC5: Consultar Asistente de IA (Core)
**Como** empleado  
**Quiero** hacer preguntas en lenguaje natural sobre la documentación de mi sector  
**Para que** obtenga respuestas precisas sin tener que leer documentos completos o molestar a compañeros

**Criterios de aceptación**:
- ✅ Puedo escribir preguntas en lenguaje natural en español
- ✅ El asistente responde basándose SOLO en la documentación de mi sector
- ✅ La respuesta incluye las fuentes consultadas (qué documentos/secciones)
- ✅ Las respuestas son contextualizadas y coherentes
- ✅ **Cada respuesta pasa evaluación de Faithfulness ≥ 0.8 (no alucina)**
- ✅ **Cada respuesta pasa evaluación de Relevancy ≥ 0.7 (es relevante)**
- ✅ El tiempo de respuesta es menor a 5 segundos
- ✅ Si no encuentra información, me lo indica claramente
- ✅ Puedo ver el historial de mi conversación

**Entregables técnicos**:
- API endpoint: `POST /api/chat/query`
- Flujo RAG completo con Genkit + Gemini 1.5 Pro
- **Genkit Evaluators configurados**:
  - `FaithfulnessEvaluator` - Mide fidelidad al contexto
  - `RelevancyEvaluator` - Mide relevancia a la pregunta
  - Logs automáticos de scores en cada respuesta
- Búsqueda semántica con pgvector (top-5 fragmentos)
- Construcción de prompt con contexto
- Sistema de citado de fuentes
- Interfaz de chat en Next.js
- Tests E2E del flujo completo
- **Tests de calidad con evaluators en modo batch**

---

#### Autenticación con Auth0
**Como** usuario  
**Quiero** autenticarme de forma segura  
**Para que** solo yo pueda acceder a la información de mi sector

**Criterios de aceptación**:
- ✅ Puedo hacer login con Auth0 (email/password)
- ✅ Mis credenciales se validan correctamente
- ✅ Los tokens se almacenan en cookies HttpOnly
- ✅ Las cookies tienen configuración segura (SameSite, Secure en prod)
- ✅ Puedo hacer logout y la sesión se invalida
- ✅ Los tokens expiran y se renuevan automáticamente

**Entregables técnicos**:
- Integración con Auth0 en backend (validación JWT con JWKS)
- Auth0 SDK en frontend (`@auth0/nextjs-auth0`)
- Guards de autenticación en NestJS
- Middleware de protección de rutas en Next.js
- API route para obtener access token server-side

---

#### Autorización Básica con Roles
**Como** sistema  
**Quiero** controlar qué usuarios pueden hacer qué acciones  
**Para que** solo los autorizados puedan subir documentos o acceder a ciertos sectores

**Criterios de aceptación**:
- ✅ Existen al menos 2 roles: `admin` y `user`
- ✅ Solo `admin` puede subir documentos
- ✅ Los usuarios solo pueden consultar documentos de sectores asignados a ellos
- ✅ El sistema valida permisos en cada request
- ✅ Los intentos de acceso no autorizado son bloqueados con error 403

**Entregables técnicos**:
- Tablas: `users`, `roles`, `user_roles`, `sectors`
- Authorization guards en NestJS
- Decoradores: `@RequirePermission()`, `@RequireSectorAccess()`
- Sistema de permisos: `knowledge:read`, `knowledge:write`, `chat:query`
- Sincronización usuario Auth0 → BD interna

---

### 2.2 Funcionalidades Excluidas ❌ (Post-MVP)

#### UC1: Gestión Avanzada de Sectores y Organización
**Estado**: Post-MVP  
**Razón**: El MVP trabajará con sectores pre-configurados (RRHH, Tech, Ventas)

**Lo que NO incluye el MVP**:
- ❌ CRUD completo de sectores desde UI
- ❌ Gestión de organizaciones múltiples
- ❌ Asignación dinámica de usuarios a sectores desde UI
- ❌ Configuración avanzada de permisos por sector

**Lo que SÍ incluye el MVP** (mínimo viable):
- ✅ Sectores pre-configurados en BD (seed data)
- ✅ Asignación de usuario a sector vía script/admin directo en BD
- ✅ Filtrado de búsqueda por sector

---

#### UC3: Generación de Cápsulas Multimedia
**Estado**: Post-MVP (Fase 2)  
**Razón**: No es crítico para validar la hipótesis principal de RAG

**Excluido del MVP**:
- ❌ Generación de videos explicativos
- ❌ Generación de audios/podcasts
- ❌ Text-to-Speech
- ❌ Guiones automáticos

---

#### UC4: Dashboard de Análisis de Sentimiento
**Estado**: Post-MVP (Fase 2)  
**Razón**: Requiere datos históricos que no existirán al inicio

**Excluido del MVP**:
- ❌ Dashboard analítico para RRHH
- ❌ Análisis de sentimiento automático
- ❌ Métricas de calidad de documentación
- ❌ Reportes de uso

**Lo que SÍ incluye el MVP**:
- ✅ Almacenamiento de mensajes y respuestas en BD
- ✅ Preparación de datos para análisis futuro

---

#### UC6: Itinerarios de Onboarding
**Estado**: Post-MVP (Fase 2)  
**Razón**: Depende de UC3 y requiere diseño de experiencia complejo

**Excluido del MVP**:
- ❌ Creación de itinerarios personalizados
- ❌ Tracking de progreso de empleado
- ❌ Milestones y contenido estructurado
- ❌ Sistema de trazabilidad (ContentSourceOrigin)

---

#### UC7: Sistema de Calificación Avanzado
**Estado**: Post-MVP  
**Razón**: No es bloqueante para la funcionalidad core

**Excluido del MVP**:
- ❌ Sistema de rating de respuestas con estrellas
- ❌ Comentarios de feedback
- ❌ Mejora continua basada en feedback

**Lo que SÍ incluye el MVP**:
- ✅ Registro básico de interacciones (para análisis posterior)

---

## 3. User Stories del MVP

### Historia 1: Primer Uso del Sistema (Admin)
```
Como administrador de RRHH
Quiero subir el "Manual de Vacaciones.pdf"
Para que los nuevos empleados puedan consultarlo

Escenario:
1. Me autentico con Auth0
2. Voy a /knowledge/upload
3. Selecciono "Manual_Vacaciones.pdf" (2MB, 15 páginas)
4. Selecciono sector: "RRHH"
5. Hago clic en "Subir"
6. Veo mensaje: "Procesando documento..." con spinner
7. Después de 30 segundos: "Documento indexado correctamente. 45 fragmentos creados"
8. Veo el documento en la lista con estado "Activo"
```

### Historia 2: Primera Consulta (Usuario)
```
Como nuevo empleado
Quiero saber cómo pedir vacaciones
Para planificar mis días libres

Escenario:
1. Me autentico con Auth0
2. Voy a /chat
3. Escribo: "¿Cómo pido vacaciones?"
4. Presiono Enter
5. Veo un indicador de "escribiendo..."
6. Después de 3 segundos recibo respuesta:
   "Debes solicitar tus vacaciones con al menos 15 días de antelación
   a través del formulario en el portal interno. El proceso es..."
7. Debajo veo: "📄 Fuentes consultadas: Manual_Vacaciones.pdf (página 5)"
8. Puedo hacer una pregunta de seguimiento
```

### Historia 3: Aislamiento por Sectores
```
Como empleado del sector Tech
Quiero hacer una consulta técnica
Para verificar que no veo información de RRHH

Escenario:
1. Estoy autenticado (asignado a sector "Tech")
2. Pregunto: "¿Cuál es el proceso de deploy?"
3. Recibo respuesta basada en "Manual_Tech_Deploy.pdf"
4. Pregunto: "¿Cómo pido vacaciones?"
5. Si no hay documentos de vacaciones en Tech, recibo:
   "No tengo información sobre eso en la documentación técnica disponible"
6. Verifico que NO recibo información del sector RRHH
```

---

## 4. Criterios de Aceptación Globales del MVP

### 4.1 Funcionalidad
- [ ] **F1**: Un admin puede subir un PDF y queda disponible para consultas en < 2 minutos
- [ ] **F2**: Un usuario puede hacer una pregunta y recibir respuesta coherente en < 5 segundos
- [ ] **F3**: Las respuestas incluyen citado de fuentes (documento + fragmento)
- [ ] **F4**: El sistema responde "No tengo información" cuando no encuentra datos
- [ ] **F5**: Los usuarios de un sector NO pueden ver información de otros sectores

### 4.2 Seguridad
- [ ] **S1**: Todos los endpoints requieren autenticación válida
- [ ] **S2**: Los tokens se almacenan en cookies HttpOnly
- [ ] **S3**: Los roles y permisos se validan en cada request
- [ ] **S4**: Los intentos no autorizados retornan 403 Forbidden
- [ ] **S5**: Las contraseñas se gestionan exclusivamente en Auth0
- [ ] **S6**: Los documentos se sanitizan antes de indexar (anti-prompt-injection)
- [ ] **S7**: Los documentos maliciosos son detectados y rechazados

### 4.3 Performance
- [ ] **P1**: Ingesta de PDF de 50 páginas completa en < 2 minutos
- [ ] **P2**: Respuesta del chat en < 5 segundos (p95)
- [ ] **P3**: Búsqueda vectorial en pgvector completa en < 500ms
- [ ] **P4**: La aplicación frontend carga en < 3 segundos (FCP)
- [ ] **P5**: El sistema soporta al menos 10 usuarios concurrentes

### 4.4 Calidad y Testing
- [ ] **T1**: Coverage de tests unitarios ≥ 80%
- [ ] **T2**: Todos los use cases tienen tests de integración
- [ ] **T3**: Existe al menos 1 test E2E del flujo completo
- [ ] **T4**: El código sigue Clean Architecture y principios SOLID
- [ ] **T5**: Todo el código está desarrollado con TDD (Red-Green-Refactor)
- [ ] **T6**: Faithfulness score promedio ≥ 0.8 en test set de 20 consultas
- [ ] **T7**: Relevancy score promedio ≥ 0.7 en test set de 20 consultas
- [ ] **T8**: Tests de seguridad contra prompt injection pasando

### 4.5 Usabilidad
- [ ] **U1**: La interfaz de chat es intuitiva (sin necesidad de tutorial)
- [ ] **U2**: Los mensajes de error son claros y accionables
- [ ] **U3**: El estado de carga es visible durante operaciones largas
- [ ] **U4**: La aplicación es responsive (funciona en móvil)
- [ ] **U5**: El historial de conversación se mantiene durante la sesión

---

## 5. Definición de "Done"

Un feature del MVP se considera **DONE** cuando:

1. ✅ **Código implementado** siguiendo Clean Architecture
2. ✅ **Tests escritos PRIMERO** (TDD - Red-Green-Refactor)
3. ✅ **Tests pasando** (unitarios, integración, E2E según aplique)
4. ✅ **Coverage mínimo** alcanzado (80% en el módulo)
5. ✅ **Code review** aprobado
6. ✅ **Documentación técnica** actualizada si aplica
7. ✅ **Sin errores de linter** ni warnings críticos
8. ✅ **Funcionalidad verificada** manualmente en entorno local
9. ✅ **Criterios de aceptación** de la user story cumplidos
10. ✅ **Integrado** en rama principal (main/develop)

---

## 6. Entregables Técnicos del MVP

### 6.1 Backend (context-ai-api)

**Módulos implementados**:
- ✅ `AuthModule` - Validación Auth0
- ✅ `AuthorizationModule` - Roles y permisos
- ✅ `KnowledgeModule` - Ingesta y búsqueda vectorial
- ✅ `InteractionModule` - Chat y RAG

**Endpoints API**:
- `POST /api/knowledge/sources` - Subir documento
- `GET /api/knowledge/sources/:sectorId` - Listar documentos
- `POST /api/chat/query` - Consultar asistente
- `GET /api/chat/conversations/:userId` - Historial
- `POST /api/auth/sync` - Sincronizar usuario

**Base de Datos**:
- PostgreSQL 16 con extensión pgvector
- Tablas: users, sectors, roles, user_roles, knowledge_sources, fragments, conversations, messages
- Migraciones iniciales
- Seed data con 3 sectores pre-configurados

**Integraciones**:
- Auth0 (validación JWT)
- Google Genkit (orquestación IA)
- Gemini 1.5 Pro (LLM)
- **Genkit Evaluators** (Faithfulness, Relevancy)

**Servicios de Seguridad**:
- `TextSanitizationService` - Limpieza y validación de contenido
- Detección de prompt injection patterns
- Validación de caracteres especiales

---

### 6.2 Frontend (context-ai-front)

**Páginas implementadas**:
- ✅ `/` - Landing page con login
- ✅ `/chat` - Interfaz de chat (protegida)
- ✅ `/knowledge/upload` - Subir documentos (admin only)
- ✅ `/knowledge` - Listar documentos del sector

**Componentes principales**:
- `ChatContainer` - Contenedor del chat
- `MessageList` - Lista de mensajes con fuentes
- `MessageInput` - Input para consultas
- `DocumentUpload` - Form de carga de archivos
- `SourceCard` - Tarjeta de fuente citada

**Autenticación**:
- Login/Logout con Auth0
- Protected routes con middleware
- Cookies HttpOnly para tokens

---

### 6.3 Shared (context-ai-shared)

**DTOs exportados**:
- `IngestDocumentDto`
- `ChatQueryDto`
- `ChatResponseDto`
- `UserDto`
- `MessageDto`

**Enums**:
- `SourceType`: PDF, MARKDOWN
- `MessageRole`: USER, ASSISTANT, SYSTEM
- `RoleType`: ADMIN, USER

---

## 7. Métricas de Éxito del MVP

### 7.1 Métricas Técnicas

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| **Uptime** | ≥ 99% | Monitoreo con Sentry |
| **Tiempo de respuesta chat** | < 5s (p95) | Logs de Genkit |
| **Tiempo de ingesta** | < 2 min para 50 páginas | Timestamps en BD |
| **Coverage de tests** | ≥ 80% | Jest coverage report |
| **Errores en producción** | < 5 por día | Sentry dashboard |

### 7.1b Métricas de Calidad de IA (Genkit Evaluators)

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| **Faithfulness Score** | ≥ 0.8 (promedio) | Genkit Evaluator en cada respuesta |
| **Relevancy Score** | ≥ 0.7 (promedio) | Genkit Evaluator en cada respuesta |
| **Respuestas con baja fidelidad** | < 10% | Respuestas con Faithfulness < 0.6 |
| **Documentos rechazados por sanitización** | Trackear % | Logs de TextSanitizationService |
| **Intentos de prompt injection detectados** | 0 en producción | Alertas de seguridad |

### 7.2 Métricas de Negocio

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| **Consultas exitosas** | ≥ 70% | Logs de respuestas |
| **Respuestas con fuentes** | 100% | Validación en código |
| **Tiempo promedio de respuesta a duda** | < 30 segundos | Timestamp consulta → respuesta |
| **Documentos indexados** | ≥ 10 en primera semana | Conteo en BD |
| **Usuarios activos** | ≥ 5 en primera semana | Sessions en Auth0 |

### 7.3 Criterio de Validación Final

El MVP se considera **EXITOSO** si después de 2 semanas de uso:

1. ✅ Al menos **5 empleados** lo han usado activamente (≥ 5 consultas cada uno)
2. ✅ Al menos **70%** de las consultas obtienen respuesta útil
3. ✅ **Faithfulness score promedio ≥ 0.8** (IA no alucina)
4. ✅ **Relevancy score promedio ≥ 0.7** (respuestas relevantes)
5. ✅ **0 incidentes** de fuga de información entre sectores
6. ✅ **0 intentos exitosos** de prompt injection
7. ✅ **0 caídas** del sistema por más de 5 minutos
8. ✅ Al menos **10 documentos** indexados en 2+ sectores

---

## 8. Riesgos y Mitigaciones del MVP

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Gemini API indisponible** | Media | Alto | Implementar retry con exponential backoff |
| **pgvector lento con muchos docs** | Media | Medio | Índices optimizados + benchmark temprano |
| **Usuarios no encuentran útiles las respuestas** | Media | Alto | **Genkit Evaluators** (Faithfulness/Relevancy) + prompt engineering iterativo |
| **Auth0 mal configurado** | Baja | Alto | Tests E2E de autenticación exhaustivos |
| **Chunks muy pequeños/grandes** | Alta | Medio | Experimentar con tamaños 300-700 tokens |
| **Prompt injection en documentos** | Media | Alto | **TextSanitizationService** + validación estricta |
| **IA alucina información** | Media | Alto | **Genkit Faithfulness Evaluator** con umbral ≥ 0.8 |

---

## 9. Plan de Rollout del MVP

### Fase 1: Desarrollo
- Semana 1-2: Setup + Knowledge Context
- Semana 3-4: Interaction Context + RAG
- Semana 5: Integración Auth0 + Authorization
- Semana 6: Tests E2E + Bug fixes

### Fase 2: Testing Interno (1 semana)
- Uso interno del equipo de desarrollo
- Carga de documentación real de 1 sector (RRHH)
- **Evaluación batch con Genkit Evaluators** (test set de 20 consultas predefinidas)
- Ajuste de prompts basado en scores de Faithfulness/Relevancy
- **Tests de seguridad con documentos maliciosos** (prompt injection)

### Fase 3: Pilot
- 5-10 usuarios voluntarios
- 1-2 sectores (RRHH + Tech)
- Feedback diario
- Iteraciones rápidas

### Fase 4: Evaluación
- Análisis de métricas
- Decisión: Go/No-Go para Fase 2 (Post-MVP)
- Planificación de siguientes features

---

## 10. Qué Viene Después del MVP

Una vez validado el MVP, las siguientes features en orden de prioridad:

**Fase 2 - Onboarding & Multimedia** (UC3, UC6):
- Generación de cápsulas multimedia
- Itinerarios de onboarding
- Sistema de trazabilidad (ContentSourceOrigin)

**Fase 3 - Analytics** (UC4, UC7):
- Dashboard de análisis para RRHH
- Sistema de calificación
- Análisis de sentimiento

**Fase 4 - Gestión Avanzada** (UC1):
- CRUD completo de sectores desde UI
- Gestión de organizaciones
- Asignación dinámica de usuarios

**Fase 5 - Optimización**:
- Caché de embeddings
- Búsqueda híbrida (vectorial + keyword)
- Fine-tuning del modelo de embeddings

---

## Resumen Ejecutivo

**El MVP de Context.ai** permite a empleados consultar documentación mediante IA (UC5) después de que un admin suba documentos (UC2), con autenticación segura (Auth0) y control de acceso por sectores (Authorization).

**Valor clave**: Reducir tiempo de onboarding y dependencia de compañeros veteranos.

**Duración estimada**: 4-6 semanas de desarrollo + 2-3 semanas de testing/pilot.

**Criterio de éxito**: ≥70% de consultas útiles, 0 fugas de información, 5+ usuarios activos.

**Excluido del MVP**: Multimedia, onboarding estructurado, analytics, gestión avanzada de organización.

