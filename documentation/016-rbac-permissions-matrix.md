# RBAC - Matriz de Permisos por Rol

## Descripción

Context.AI implementa un sistema de control de acceso basado en roles (RBAC) con tres roles predefinidos y 10 permisos granulares. Cada usuario tiene un rol asignado que determina las acciones que puede realizar en el sistema.

---

## Roles del Sistema

| Rol | Permisos | Descripción |
|-----|----------|-------------|
| **admin** | 10 | Acceso completo al sistema |
| **manager** | 8 | Gestión de conocimiento + lectura de usuarios |
| **user** | 4 | Acceso básico — chat y lectura |

---

## Matriz de Permisos

| Permiso | Descripción | 🟢 user | 🟡 manager | 🔴 admin |
|---------|-------------|:-------:|:----------:|:--------:|
| `chat:read` | Usar chat e interactuar con IA | ✅ | ✅ | ✅ |
| `knowledge:read` | Ver documentos de conocimiento | ✅ | ✅ | ✅ |
| `knowledge:create` | Subir y crear documentos | ❌ | ✅ | ✅ |
| `knowledge:update` | Editar documentos | ❌ | ✅ | ✅ |
| `knowledge:delete` | Eliminar documentos | ❌ | ✅ | ✅ |
| `profile:read` | Ver perfil propio | ✅ | ✅ | ✅ |
| `profile:update` | Actualizar perfil propio | ✅ | ✅ | ✅ |
| `users:read` | Ver información de usuarios | ❌ | ✅ | ✅ |
| `users:manage` | Gestionar usuarios (activar/desactivar) | ❌ | ❌ | ✅ |
| `system:admin` | Administración completa del sistema | ❌ | ❌ | ✅ |

---

## Detalle por Rol

### 🟢 User (4 permisos)

Rol base asignado automáticamente al registrarse. Permite interactuar con el asistente IA y consultar la base de conocimiento.

- `chat:read` — Usar chat e interactuar con IA
- `knowledge:read` — Ver documentos de conocimiento
- `profile:read` — Ver perfil propio
- `profile:update` — Actualizar perfil propio

### 🟡 Manager (8 permisos)

Rol intermedio para gestores de contenido. Permite la administración completa de la base de conocimiento y visualización de usuarios.

- Todo lo del rol `user` +
- `knowledge:create` — Subir y crear documentos de conocimiento
- `knowledge:update` — Editar documentos de conocimiento
- `knowledge:delete` — Eliminar documentos de conocimiento
- `users:read` — Ver información de usuarios

### 🔴 Admin (10 permisos)

Rol con acceso total al sistema. Incluye gestión de usuarios y administración del sistema.

- Todo lo del rol `manager` +
- `users:manage` — Gestionar usuarios (activar/desactivar)
- `system:admin` — Administración completa del sistema

---

## Implementación Técnica

### Decorador en Controladores

Los permisos se aplican en los endpoints del API mediante el decorador `@RequirePermissions`:

```typescript
@RequirePermissions(['knowledge:create'])
async uploadDocument(...) { }

@RequirePermissions(['knowledge:delete'])
async deleteDocument(...) { }

@RequirePermissions(['system:admin'])
async adminAction(...) { }
```

### Tablas en PostgreSQL

El sistema RBAC se almacena en las siguientes tablas:

| Tabla | Descripción |
|-------|-------------|
| `roles` | Definición de roles (admin, manager, user) |
| `permissions` | Catálogo de permisos del sistema |
| `role_permissions` | Relación N:N entre roles y permisos |
| `user_roles` | Asignación de rol a cada usuario |

### Flujo de Autorización

```
Request HTTP
  → JwtAuthGuard (valida token JWT)
    → RBACGuard (verifica permisos del usuario)
      → Controller (ejecuta acción)
```

1. **JwtAuthGuard** valida el token JWT y extrae el usuario
2. **RBACGuard** consulta los permisos del usuario según su rol
3. Si el usuario tiene el permiso requerido, se ejecuta la acción
4. Si no, se retorna `403 Forbidden`

---

## Referencias

- Implementación RBAC: `context-ai-api/src/modules/auth/`
- Guards: `context-ai-api/src/modules/auth/guards/`
- Decoradores: `context-ai-api/src/modules/auth/decorators/`
- Migración SQL: `context-ai-api/migrations/init/003_rbac_tables.sql`
- Seeder: `context-ai-api/src/modules/auth/application/services/rbac-seeder.service.ts`

