---
name: Fase 6 - Autenticación y Autorización
overview: "Descomposición de la Fase 6 del MVP en issues granulares para implementar autenticación con Auth0 y sistema de autorización interno basado en roles. Incluye validación de JWT, guards, middleware, sincronización de usuarios, gestión de permisos, logout flow, rate limiting y audit logging."
phase: 6
parent_phase: "009-plan-implementacion-detallado.md"
total_issues: 17
---

# Fase 6: Autenticación con Auth0 y Autorización Interna

Descomposición en issues manejables para implementar el sistema completo de autenticación y autorización del MVP.

---

## Issue 6.1: Setup Auth0 Configuration and Environment Variables

**Prioridad:** Alta  
**Dependencias:** Ninguna  
**Estimación:** 3 horas

### Descripción

Configurar Auth0 tenant, crear aplicación, definir audiences, y establecer variables de entorno en backend y frontend.

### Acceptance Criteria

- [ ] Auth0 tenant creado y configurado
- [ ] Application (SPA) creada en Auth0 para frontend
- [ ] API creada en Auth0 con audience definido
- [ ] Variables de entorno configuradas en backend (.env)
- [ ] Variables de entorno configuradas en frontend (.env.local)
- [ ] Callback URLs y Logout URLs configurados
- [ ] CORS settings habilitados en Auth0
- [ ] Documentación de configuración creada

### Files to Create

```
context-ai-api/.env.auth0.example      # Template de variables Auth0 backend
context-ai-front/.env.auth0.example    # Template de variables Auth0 frontend
docs/AUTH0_SETUP.md                    # Guía de configuración de Auth0
```

### Technical Notes

**Variables necesarias Backend:**
```bash
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_AUDIENCE=https://api.contextai.com
AUTH0_ISSUER_BASE_URL=https://your-tenant.auth0.com/
```

**Variables necesarias Frontend:**
```bash
AUTH0_SECRET=<generate-with-openssl-rand-hex-32>
AUTH0_BASE_URL=http://localhost:3000
AUTH0_ISSUER_BASE_URL=https://your-tenant.auth0.com
AUTH0_CLIENT_ID=<from-auth0-application>
AUTH0_CLIENT_SECRET=<from-auth0-application>
AUTH0_AUDIENCE=https://api.contextai.com
```

---

## Issue 6.2: Implement Backend Auth Module Structure

**Prioridad:** Alta  
**Dependencias:** 6.1  
**Estimación:** 4 horas

### Descripción

Crear la estructura base del módulo de autenticación en el backend con NestJS, incluyendo módulo, servicios base y configuración de dependencias.

### Acceptance Criteria

- [ ] AuthModule creado y registrado en AppModule
- [ ] Estructura de carpetas organizada (guards/, strategies/, decorators/)
- [ ] Dependencias instaladas (passport, jwks-rsa, etc.)
- [ ] ConfigService integrado para variables Auth0
- [ ] Tests unitarios básicos del módulo
- [ ] Documentación de arquitectura del módulo

### Files to Create

```
src/modules/auth/auth.module.ts              # Módulo principal
src/modules/auth/auth.service.ts             # Servicio de autenticación
src/modules/auth/guards/.gitkeep             # Carpeta para guards
src/modules/auth/strategies/.gitkeep         # Carpeta para strategies
src/modules/auth/decorators/.gitkeep         # Carpeta para decoradores
test/unit/modules/auth/auth.module.spec.ts   # Tests del módulo
```

### Technical Notes

```typescript
// Dependencias a instalar
pnpm add @nestjs/passport passport passport-jwt jwks-rsa
pnpm add -D @types/passport-jwt
```

---

## Issue 6.3: Implement JWT Strategy with JWKS Validation

**Prioridad:** Alta  
**Dependencias:** 6.2  
**Estimación:** 6 horas

### Descripción

Implementar estrategia de Passport para validar tokens JWT de Auth0 usando JWKS (JSON Web Key Set) con caché y rate limiting.

### Acceptance Criteria

- [ ] JwtStrategy implementada con validación JWKS
- [ ] Caché habilitado para keys (mejora performance)
- [ ] Rate limiting configurado para requests JWKS
- [ ] Extrae auth0_user_id del token (claim 'sub')
- [ ] Valida audience y issuer correctamente
- [ ] Manejo de errores de tokens inválidos/expirados
- [ ] Tests unitarios con mocks de JWKS
- [ ] Tests de integración con tokens reales

### Files to Create

```
src/modules/auth/strategies/jwt.strategy.ts       # Estrategia JWT
src/modules/auth/types/jwt-payload.type.ts        # Tipos del payload
test/unit/modules/auth/strategies/jwt.strategy.spec.ts  # Tests
test/integration/auth/jwt-validation.spec.ts      # Tests integración
```

### Technical Notes

```typescript
// Estructura de la estrategia
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, ExtractJwt } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      secretOrKeyProvider: passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `https://${configService.get('AUTH0_DOMAIN')}/.well-known/jwks.json`,
      }),
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      audience: configService.get('AUTH0_AUDIENCE'),
      issuer: `https://${configService.get('AUTH0_DOMAIN')}/`,
      algorithms: ['RS256'],
    });
  }

  async validate(payload: JwtPayload): Promise<ValidatedUser> {
    return {
      auth0Id: payload.sub,
      email: payload.email,
      permissions: payload.permissions || [],
    };
  }
}
```

---

## Issue 6.4: Implement Auth Guard (JWT Authentication)

**Prioridad:** Alta  
**Dependencias:** 6.3  
**Estimación:** 4 horas

### Descripción

Crear guard que valida el token JWT en cada request protegido y extrae información del usuario autenticado.

### Acceptance Criteria

- [ ] JwtAuthGuard implementado extendiendo AuthGuard('jwt')
- [ ] Manejo de errores de autenticación con mensajes claros
- [ ] Guard aplicable a nivel de controlador o método
- [ ] Contexto de request incluye usuario validado
- [ ] Tests unitarios del guard
- [ ] Tests de integración con requests HTTP

### Files to Create

```
src/modules/auth/guards/jwt-auth.guard.ts          # Guard principal
src/modules/auth/guards/index.ts                   # Barrel export
test/unit/modules/auth/guards/jwt-auth.guard.spec.ts  # Tests
```

### Technical Notes

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser = ValidatedUser>(
    err: Error | null,
    user: TUser | false,
    info: unknown,
  ): TUser {
    if (err || !user) {
      throw new UnauthorizedException(
        'Invalid or expired authentication token',
      );
    }
    return user;
  }
}
```

---

## Issue 6.5: Implement CurrentUser Decorator

**Prioridad:** Media  
**Dependencias:** 6.4  
**Estimación:** 2 horas

### Descripción

Crear decorador personalizado para extraer el usuario autenticado del contexto de request de forma limpia en los controladores.

### Acceptance Criteria

- [ ] Decorador @CurrentUser() implementado
- [ ] Extrae usuario del contexto de request
- [ ] Tipado correcto con TypeScript
- [ ] Funciona con JwtAuthGuard
- [ ] Tests unitarios del decorador
- [ ] Ejemplos de uso documentados

### Files to Create

```
src/modules/auth/decorators/current-user.decorator.ts  # Decorador
src/modules/auth/decorators/index.ts                   # Barrel export
test/unit/modules/auth/decorators/current-user.decorator.spec.ts  # Tests
```

### Technical Notes

```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);

// Uso en controladores
@Get('profile')
@UseGuards(JwtAuthGuard)
async getProfile(@CurrentUser() user: ValidatedUser) {
  return user;
}
```

---

## Issue 6.6: Implement User Synchronization Service

**Prioridad:** Alta  
**Dependencias:** 6.4  
**Estimación:** 8 horas

### Descripción

Crear servicio que sincroniza usuarios de Auth0 con la base de datos interna, creando registro en primera autenticación y actualizando en logins subsecuentes.

### Acceptance Criteria

- [ ] UserSyncService implementado con findOrCreate logic
- [ ] Se crea usuario en BD si no existe (por auth0_user_id)
- [ ] Se actualiza información en logins subsecuentes
- [ ] Sincroniza metadata de Auth0 (picture, locale, nickname)
- [ ] Maneja cambios de email en Auth0 correctamente
- [ ] Asigna rol por defecto ('user') a nuevos usuarios
- [ ] Transacciones para garantizar consistencia
- [ ] Logging de sincronizaciones
- [ ] Tests unitarios con mocks de repositorio
- [ ] Tests de integración con BD real

### Files to Create

```
src/modules/auth/services/user-sync.service.ts           # Servicio de sync
src/modules/auth/services/index.ts                       # Barrel export
test/unit/modules/auth/services/user-sync.service.spec.ts  # Tests unitarios
test/integration/auth/user-sync.integration.spec.ts      # Tests integración
```

### Technical Notes

```typescript
@Injectable()
export class UserSyncService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly roleRepository: RoleRepository,
  ) {}

  async findOrCreateUser(auth0User: Auth0UserInfo): Promise<User> {
    // 1. Buscar por auth0_user_id
    let user = await this.userRepository.findByAuth0Id(auth0User.sub);
    
    if (!user) {
      // 2. Crear nuevo usuario con rol por defecto y metadata
      const defaultRole = await this.roleRepository.findByName('user');
      user = await this.userRepository.create({
        auth0UserId: auth0User.sub,
        email: auth0User.email,
        name: auth0User.name,
        picture: auth0User.picture, // Metadata de Auth0
        locale: auth0User.locale,   // Metadata de Auth0
        nickname: auth0User.nickname, // Metadata de Auth0
        roles: [defaultRole],
      });
    } else {
      // 3. Actualizar información si cambió (incluyendo metadata)
      user = await this.userRepository.update(user.id, {
        email: auth0User.email,
        name: auth0User.name,
        picture: auth0User.picture,
        locale: auth0User.locale,
        nickname: auth0User.nickname,
        lastLogin: new Date(),
      });
    }
    
    return user;
  }
}
```

---

## Issue 6.7: Implement Authorization Module Structure

**Prioridad:** Alta  
**Dependencias:** 6.2  
**Estimación:** 4 hours

### Descripción

Crear módulo de autorización separado del de autenticación, que manejará roles, permisos y control de acceso basado en recursos.

### Acceptance Criteria

- [ ] AuthorizationModule creado y registrado
- [ ] Estructura de carpetas organizada
- [ ] Separación clara de autenticación vs autorización
- [ ] RolesService base implementado
- [ ] Tests unitarios del módulo
- [ ] Documentación de diferencia Auth vs AuthZ

### Files to Create

```
src/modules/authorization/authorization.module.ts         # Módulo
src/modules/authorization/services/roles.service.ts       # Servicio de roles
src/modules/authorization/guards/.gitkeep                 # Guards folder
src/modules/authorization/decorators/.gitkeep             # Decorators folder
test/unit/modules/authorization/authorization.module.spec.ts  # Tests
docs/AUTH_VS_AUTHZ.md                                     # Documentación
```

### Technical Notes

**Diferencia clave:**
- **Authentication (Auth0):** ¿Quién eres? Valida identidad con JWT
- **Authorization (Interno):** ¿Qué puedes hacer? Valida permisos por roles

---

## Issue 6.8: Implement Roles and Permissions Service

**Prioridad:** Alta  
**Dependencias:** 6.7  
**Estimación:** 8 horas

### Descripción

Implementar servicio completo para gestión de roles y permisos, incluyendo CRUD de roles, asignación a usuarios y verificación de permisos.

### Acceptance Criteria

- [ ] RolesService implementado con CRUD completo
- [ ] PermissionsService para verificar permisos
- [ ] Permisos definidos como constantes (knowledge:read, chat:query, etc.)
- [ ] Método checkPermission(user, permission) implementado
- [ ] Método checkSectorAccess(user, sectorId) implementado
- [ ] Caché de permisos para performance
- [ ] Tests unitarios completos (TDD)
- [ ] Tests de integración con BD

### Files to Create

```
src/modules/authorization/services/roles.service.ts           # Servicio roles
src/modules/authorization/services/permissions.service.ts     # Servicio permisos
src/modules/authorization/constants/permissions.constant.ts   # Constantes
test/unit/modules/authorization/services/roles.service.spec.ts      # Tests
test/unit/modules/authorization/services/permissions.service.spec.ts  # Tests
```

### Technical Notes

```typescript
// Definición de permisos
export enum Permission {
  KNOWLEDGE_READ = 'knowledge:read',
  KNOWLEDGE_WRITE = 'knowledge:write',
  CHAT_QUERY = 'chat:query',
  ADMIN_MANAGE_SECTORS = 'admin:manage_sectors',
  ADMIN_MANAGE_ROLES = 'admin:manage_roles',
}

// Verificación de permisos
@Injectable()
export class PermissionsService {
  async checkPermission(user: User, permission: Permission): Promise<boolean> {
    const userPermissions = await this.getUserPermissions(user.id);
    return userPermissions.includes(permission);
  }
  
  async checkSectorAccess(user: User, sectorId: string): Promise<boolean> {
    // Verificar si user tiene acceso al sector
    return user.sectors.some(s => s.id === sectorId);
  }
}
```

---

## Issue 6.9: Implement Authorization Guard (Permissions)

**Prioridad:** Alta  
**Dependencias:** 6.8  
**Estimación:** 6 horas

### Descripción

Crear guard que valida permisos basados en roles después de que el usuario ha sido autenticado, permitiendo control granular de acceso.

### Acceptance Criteria

- [ ] PermissionsGuard implementado
- [ ] Se ejecuta después de JwtAuthGuard
- [ ] Lee metadata de decoradores para obtener permisos requeridos
- [ ] Valida permisos del usuario contra los requeridos
- [ ] Manejo de errores con ForbiddenException
- [ ] Tests unitarios con diferentes escenarios
- [ ] Tests de integración en endpoints reales

### Files to Create

```
src/modules/authorization/guards/permissions.guard.ts      # Guard de permisos
src/modules/authorization/guards/index.ts                  # Barrel export
test/unit/modules/authorization/guards/permissions.guard.spec.ts  # Tests
```

### Technical Notes

```typescript
@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly permissionsService: PermissionsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.get<Permission[]>(
      'permissions',
      context.getHandler(),
    );

    if (!requiredPermissions) {
      return true; // No permissions required
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    for (const permission of requiredPermissions) {
      const hasPermission = await this.permissionsService.checkPermission(
        user,
        permission,
      );
      if (!hasPermission) {
        throw new ForbiddenException(
          `Missing required permission: ${permission}`,
        );
      }
    }

    return true;
  }
}
```

---

## Issue 6.10: Implement Permission Decorators

**Prioridad:** Media  
**Dependencias:** 6.9  
**Estimación:** 4 horas

### Descripción

Crear decoradores personalizados para declarar permisos requeridos y acceso a sectores de forma declarativa en controladores.

### Acceptance Criteria

- [ ] @RequirePermission() decorador implementado
- [ ] @RequireSectorAccess() decorador implementado
- [ ] Decoradores funcionan con PermissionsGuard
- [ ] Soporte para múltiples permisos
- [ ] Tests unitarios de decoradores
- [ ] Ejemplos de uso documentados

### Files to Create

```
src/modules/authorization/decorators/require-permission.decorator.ts  # Decorator
src/modules/authorization/decorators/require-sector-access.decorator.ts  # Decorator
src/modules/authorization/decorators/index.ts                         # Barrel export
test/unit/modules/authorization/decorators/decorators.spec.ts         # Tests
```

### Technical Notes

```typescript
// require-permission.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { Permission } from '../constants/permissions.constant';

export const RequirePermission = (...permissions: Permission[]) =>
  SetMetadata('permissions', permissions);

// Uso en controladores
@Controller('knowledge')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class KnowledgeController {
  
  @Post('sources')
  @RequirePermission(Permission.KNOWLEDGE_WRITE)
  async uploadDocument(@CurrentUser() user: User, @Body() dto: IngestDocumentDto) {
    // Usuario está autenticado Y tiene permiso knowledge:write
  }
}
```

---

## Issue 6.11: Implement Frontend Auth0 Integration

**Prioridad:** Alta  
**Dependencias:** 6.1  
**Estimación:** 8 horas

### Descripción

Integrar Auth0 SDK en Next.js con configuración de cookies HttpOnly seguras, rutas de autenticación y provider de sesión.

### Acceptance Criteria

- [ ] @auth0/nextjs-auth0 instalado y configurado
- [ ] API routes de Auth0 implementadas (/api/auth/[auth0])
- [ ] Configuración de sesión con cookies HttpOnly
- [ ] UserProvider integrado en layout raíz
- [ ] Login/Logout flows funcionando
- [ ] Callback handling implementado
- [ ] Tests de integración del flujo completo
- [ ] Documentación de configuración

### Files to Create

```
app/api/auth/[auth0]/route.ts          # Dynamic route para Auth0
lib/auth0.config.ts                    # Configuración de Auth0
app/layout.tsx                         # Layout con UserProvider (actualizar)
components/auth/LoginButton.tsx        # Botón de login/logout
components/auth/UserProfile.tsx        # Componente de perfil de usuario
test/e2e/auth/login-flow.spec.ts       # Tests E2E del flujo
```

### Technical Notes

```typescript
// app/api/auth/[auth0]/route.ts
import { handleAuth, handleLogin } from '@auth0/nextjs-auth0';

export const GET = handleAuth({
  login: handleLogin({
    returnTo: '/chat',
    authorizationParams: {
      audience: process.env.AUTH0_AUDIENCE,
      scope: 'openid profile email offline_access',
    },
  }),
});

// Dependencias
pnpm add @auth0/nextjs-auth0
```

---

## Issue 6.12: Implement Access Token Retrieval for API Calls

**Prioridad:** Alta  
**Dependencias:** 6.11  
**Estimación:** 5 horas

### Descripción

Crear mecanismo para obtener access token desde cookies HttpOnly en server-side y enviarlo en requests al backend.

### Acceptance Criteria

- [ ] API route /api/auth/token implementada
- [ ] Obtiene access token desde sesión server-side
- [ ] Manejo de token expirado con refresh automático
- [ ] Interceptor de axios actualizado para usar el token
- [ ] Error handling para casos sin autenticación
- [ ] Tests unitarios del token retrieval
- [ ] Tests de integración con API backend

### Files to Create

```
app/api/auth/token/route.ts            # Route para obtener token
lib/api/client.ts                      # Cliente axios (actualizar)
lib/api/token-manager.ts               # Gestor de tokens
test/unit/lib/api/token-manager.spec.ts  # Tests
```

### Technical Notes

```typescript
// app/api/auth/token/route.ts
import { getAccessToken } from '@auth0/nextjs-auth0';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const { accessToken } = await getAccessToken();
    return NextResponse.json({ accessToken });
  } catch (error) {
    return NextResponse.json({ accessToken: null }, { status: 401 });
  }
}

// lib/api/client.ts - Interceptor actualizado
apiClient.interceptors.request.use(async (config) => {
  const response = await fetch('/api/auth/token');
  const { accessToken } = await response.json();
  
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  
  return config;
});
```

---

## Issue 6.13: Implement Protected Routes Middleware

**Prioridad:** Alta  
**Dependencias:** 6.11  
**Estimación:** 4 horas

### Descripción

Configurar middleware de Next.js para proteger rutas que requieren autenticación, redirigiendo a login cuando sea necesario.

### Acceptance Criteria

- [ ] Middleware implementado con withMiddlewareAuthRequired
- [ ] Rutas protegidas definidas en config.matcher
- [ ] Redirección a login para usuarios no autenticados
- [ ] Manejo de returnTo después de login
- [ ] Tests de diferentes rutas protegidas
- [ ] Documentación de rutas públicas vs protegidas

### Files to Create

```
middleware.ts                          # Middleware de Next.js
lib/constants/routes.ts                # Constantes de rutas
test/e2e/auth/protected-routes.spec.ts # Tests E2E
```

### Technical Notes

```typescript
// middleware.ts
import { withMiddlewareAuthRequired } from '@auth0/nextjs-auth0/edge';

export default withMiddlewareAuthRequired();

export const config = {
  matcher: [
    '/chat/:path*',
    '/knowledge/:path*',
    '/dashboard/:path*',
  ],
};
```

---

## Issue 6.14: Integration Testing for Complete Auth Flow

**Prioridad:** Alta  
**Dependencias:** Todas las anteriores  
**Estimación:** 10 horas

### Descripción

Crear suite completa de tests end-to-end que validen el flujo completo de autenticación y autorización desde login hasta acceso a recursos protegidos.

### Acceptance Criteria

- [ ] Test E2E: Login completo desde frontend a backend
- [ ] Test E2E: Sincronización de usuario en primer login
- [ ] Test E2E: Acceso a endpoint protegido con token válido
- [ ] Test E2E: Denegación de acceso sin permisos
- [ ] Test E2E: Logout y limpieza de sesión
- [ ] Test E2E: Renovación automática de token
- [ ] Test: Sector access control funciona
- [ ] Tests corren en CI/CD
- [ ] Coverage >= 80% en módulos auth/authorization

### Files to Create

```
test/e2e/auth/complete-auth-flow.e2e.spec.ts      # Tests E2E completos
test/e2e/auth/authorization-flow.e2e.spec.ts      # Tests de autorización
test/integration/auth/full-integration.spec.ts    # Tests de integración
test/fixtures/auth-test-data.ts                   # Datos de prueba
test/helpers/auth-test-helpers.ts                 # Utilidades para tests
```

### Technical Notes

```typescript
// Ejemplo de test E2E completo
describe('Complete Authentication Flow (E2E)', () => {
  let accessToken: string;

  it('should login user and get access token', async () => {
    // 1. Simular login con Auth0
    const loginResponse = await request(app.getHttpServer())
      .post('/api/auth/login')
      .expect(302);
    
    // 2. Obtener token de callback
    accessToken = extractTokenFromCallback(loginResponse);
    expect(accessToken).toBeDefined();
  });

  it('should create user in database on first login', async () => {
    const user = await userRepository.findByAuth0Id(testAuth0Id);
    expect(user).toBeDefined();
    expect(user.email).toBe('test@example.com');
    expect(user.roles).toContainEqual(expect.objectContaining({ name: 'user' }));
  });

  it('should access protected endpoint with valid token', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/chat/conversations')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    
    expect(response.body).toBeDefined();
  });

  it('should deny access without required permission', async () => {
    await request(app.getHttpServer())
      .post('/api/knowledge/sources')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ /* data */ })
      .expect(403);
  });
});
```

---

## Issue 6.15: Implement Complete Logout Flow

**Prioridad:** Alta  
**Dependencias:** 6.11  
**Estimación:** 4 horas

### Descripción

Implementar flujo completo de logout que invalida sesión en Auth0, limpia cookies, limpia estado de la aplicación y redirige correctamente.

### Acceptance Criteria

- [ ] Endpoint de logout en backend
- [ ] Invalida sesión en Auth0
- [ ] Limpia todas las cookies HttpOnly
- [ ] Limpia estado de Zustand en frontend
- [ ] Redirect a landing page después de logout
- [ ] Confirmación antes de logout (opcional)
- [ ] Manejo de errores durante logout
- [ ] Tests del flujo completo

### Files to Create

```
app/api/auth/logout/route.ts           # API route para logout
components/auth/LogoutButton.tsx       # Botón de logout (actualizar)
components/auth/LogoutConfirmDialog.tsx # Diálogo de confirmación
hooks/useLogout.ts                     # Hook personalizado
lib/utils/cleanup-on-logout.ts         # Utilidades de limpieza
```

### Technical Notes

```typescript
// app/api/auth/logout/route.ts
import { handleLogout } from '@auth0/nextjs-auth0';

export const GET = handleLogout({
  returnTo: '/',
});

// hooks/useLogout.ts
'use client';

import { useRouter } from 'next/navigation';
import { useChatStore } from '@/stores/chat.store';
import { useUserStore } from '@/stores/user.store';

export function useLogout() {
  const router = useRouter();
  const clearChat = useChatStore((state) => state.clearMessages);
  const resetUser = useUserStore((state) => state.reset);

  const logout = async () => {
    try {
      // 1. Limpiar estados locales
      clearChat();
      resetUser();
      
      // 2. Limpiar session storage
      sessionStorage.clear();
      
      // 3. Llamar a logout de Auth0
      await fetch('/api/auth/logout');
      
      // 4. Redirect
      router.push('/');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return { logout };
}

// components/auth/LogoutButton.tsx
'use client';

import { useLogout } from '@/hooks/useLogout';
import { useState } from 'react';

export function LogoutButton() {
  const { logout } = useLogout();
  const [showConfirm, setShowConfirm] = useState(false);

  const handleLogout = async () => {
    setShowConfirm(false);
    await logout();
  };

  return (
    <>
      <button onClick={() => setShowConfirm(true)}>
        Cerrar sesión
      </button>
      {showConfirm && (
        <LogoutConfirmDialog
          onConfirm={handleLogout}
          onCancel={() => setShowConfirm(false)}
        />
      )}
    </>
  );
}
```

---

## Issue 6.16: Implement Rate Limiting

**Prioridad:** Alta  
**Dependencias:** 6.2  
**Estimación:** 6 horas

### Descripción

Implementar rate limiting en endpoints críticos para prevenir abuso, DDoS y mejorar seguridad del sistema.

### Acceptance Criteria

- [ ] Rate limiting implementado con @nestjs/throttler
- [ ] Límites configurables por endpoint
- [ ] Límites más estrictos para autenticación
- [ ] Headers de rate limit en respuestas
- [ ] Respuestas 429 Too Many Requests
- [ ] Persistencia en Redis (opcional MVP)
- [ ] Tests de rate limiting
- [ ] Documentación de límites

### Files to Create

```
src/config/throttle.config.ts          # Configuración de rate limiting
src/common/decorators/throttle-custom.decorator.ts  # Decorador personalizado
test/e2e/security/rate-limiting.e2e.spec.ts  # Tests
```

### Technical Notes

```typescript
// app.module.ts
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000, // 1 segundo
        limit: 10, // 10 requests
      },
      {
        name: 'medium',
        ttl: 60000, // 1 minuto
        limit: 100, // 100 requests
      },
      {
        name: 'long',
        ttl: 3600000, // 1 hora
        limit: 1000, // 1000 requests
      },
    ]),
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}

// Uso en controladores
@Controller('auth')
export class AuthController {
  
  @Post('login')
  @Throttle({ short: { limit: 5, ttl: 60000 } }) // 5 intentos por minuto
  async login(@Body() dto: LoginDto) {
    // ...
  }
}

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  
  @Post('query')
  @Throttle({ medium: { limit: 30, ttl: 60000 } }) // 30 queries por minuto
  async query(@Body() dto: QueryDto) {
    // ...
  }
}

// Dependencias
pnpm add @nestjs/throttler
pnpm add -D ioredis @types/ioredis  // Para persistencia en Redis
```

---

## Issue 6.17: Implement Audit Logging

**Prioridad:** Media  
**Dependencias:** 6.6  
**Estimación:** 6 horas

### Descripción

Implementar sistema de audit logging para registrar eventos de seguridad críticos (logins, logouts, cambios de roles, accesos denegados) para compliance y debugging.

### Acceptance Criteria

- [ ] AuditLog entity y repository creados
- [ ] Interceptor registra eventos automáticamente
- [ ] Logs de login/logout
- [ ] Logs de cambios de roles/permisos
- [ ] Logs de accesos denegados (403)
- [ ] Logs incluyen IP, user agent, timestamp
- [ ] Rotación de logs (retention policy)
- [ ] Tests del audit logging

### Files to Create

```
src/modules/audit/audit.module.ts      # Módulo de auditoría
src/modules/audit/entities/audit-log.entity.ts  # Entidad
src/modules/audit/audit.service.ts     # Servicio
src/common/interceptors/audit.interceptor.ts  # Interceptor
src/modules/audit/migrations/CreateAuditLogTable.ts  # Migración
test/unit/modules/audit/audit.service.spec.ts  # Tests
```

### Technical Notes

```typescript
// entities/audit-log.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

export enum AuditEventType {
  LOGIN = 'LOGIN',
  LOGOUT = 'LOGOUT',
  LOGIN_FAILED = 'LOGIN_FAILED',
  ROLE_CHANGED = 'ROLE_CHANGED',
  ACCESS_DENIED = 'ACCESS_DENIED',
  PERMISSION_CHANGED = 'PERMISSION_CHANGED',
}

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: AuditEventType })
  eventType: AuditEventType;

  @Column({ nullable: true })
  userId?: string;

  @Column()
  ipAddress: string;

  @Column()
  userAgent: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;
}

// audit.service.ts
@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private readonly auditRepository: Repository<AuditLog>,
  ) {}

  async log(
    eventType: AuditEventType,
    req: Request,
    userId?: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.auditRepository.save({
      eventType,
      userId,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
      metadata,
    });
  }

  async findByUser(userId: string, limit = 100): Promise<AuditLog[]> {
    return this.auditRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }
}

// Uso en guards
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly auditService: AuditService) {
    super();
  }

  handleRequest<TUser = ValidatedUser>(
    err: Error | null,
    user: TUser | false,
    info: unknown,
    context: ExecutionContext,
  ): TUser {
    const request = context.switchToHttp().getRequest();

    if (err || !user) {
      // Log failed authentication
      this.auditService.log(
        AuditEventType.LOGIN_FAILED,
        request,
        undefined,
        { error: err?.message },
      );
      throw new UnauthorizedException('Invalid authentication token');
    }

    // Log successful login
    this.auditService.log(
      AuditEventType.LOGIN,
      request,
      (user as ValidatedUser).id,
    );

    return user;
  }
}
```

---

## Resumen y Orden de Implementación

### Fase 1: Setup y Configuración (Secuencial)
1. Issue 6.1: Setup Auth0 Configuration
2. Issue 6.2: Implement Backend Auth Module Structure
3. Issue 6.7: Implement Authorization Module Structure

### Fase 2: Backend Authentication (Secuencial)
4. Issue 6.3: Implement JWT Strategy with JWKS
5. Issue 6.4: Implement Auth Guard
6. Issue 6.5: Implement CurrentUser Decorator
7. Issue 6.6: Implement User Synchronization Service

### Fase 3: Backend Authorization (Secuencial)
8. Issue 6.8: Implement Roles and Permissions Service
9. Issue 6.9: Implement Authorization Guard
10. Issue 6.10: Implement Permission Decorators

### Fase 4: Frontend Integration (Secuencial)
11. Issue 6.11: Implement Frontend Auth0 Integration
12. Issue 6.12: Implement Access Token Retrieval
13. Issue 6.13: Implement Protected Routes Middleware
14. Issue 6.15: Implement Complete Logout Flow

### Fase 5: Security & Compliance (Paralelo)
15. Issue 6.16: Implement Rate Limiting
16. Issue 6.17: Implement Audit Logging

### Fase 6: Testing y Validación
17. Issue 6.14: Integration Testing for Complete Auth Flow

---

## Estimación Total

**Total de horas estimadas:** 92 horas (76 + 16 de nuevos issues)  
**Total de sprints (2 semanas c/u):** ~2-3 sprints  
**Desarrolladores recomendados:** 2 (1 backend + 1 frontend)

---

## Dependencias Externas

### Backend NPM Packages

```bash
# Autenticación
pnpm add @nestjs/passport passport passport-jwt jwks-rsa
pnpm add -D @types/passport-jwt

# Utilidades
pnpm add bcrypt
pnpm add -D @types/bcrypt

# Rate Limiting
pnpm add @nestjs/throttler
pnpm add -D ioredis @types/ioredis
```

### Frontend NPM Packages

```bash
# Auth0
pnpm add @auth0/nextjs-auth0

# Opcional: gestión de sesión
pnpm add iron-session
```

---

## Modelo de Base de Datos

### Tablas Necesarias (si no existen)

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth0_user_id VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- Roles table
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  permissions JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User_Roles table (many-to-many)
CREATE TABLE user_roles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  sector_id UUID REFERENCES sectors(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id, sector_id)
);

-- Indexes
CREATE INDEX idx_users_auth0_id ON users(auth0_user_id);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
```

---

## Security Considerations

### Backend Security

1. **JWT Validation:**
   - Siempre validar signature con JWKS
   - Verificar audience y issuer
   - Implementar rate limiting en JWKS requests

2. **Authorization:**
   - Nunca confiar en permisos del token
   - Siempre verificar permisos en BD
   - Implementar caché con TTL corto (5 min)

3. **Error Handling:**
   - No exponer detalles internos en errores
   - Logs detallados server-side
   - Mensajes genéricos al cliente

### Frontend Security

1. **Cookies:**
   - HttpOnly: true (no accesibles desde JS)
   - Secure: true en producción (solo HTTPS)
   - SameSite: 'lax' (protección CSRF)

2. **Tokens:**
   - Nunca almacenar en localStorage
   - Nunca exponer en logs del cliente
   - Obtener siempre server-side

3. **CORS:**
   - Configurar origins permitidos
   - credentials: true para cookies
   - Validar en backend

---

## Testing Strategy

### Unit Tests
- Cada service, guard y decorator
- Mocks de dependencias externas
- Coverage >= 80%

### Integration Tests
- Validación real con Auth0 (test tenant)
- Base de datos de testing
- Flujos completos de auth/authz

### E2E Tests
- Playwright para frontend
- Supertest para backend
- Flujos usuario completos

---

## Validación de Completitud

La Fase 6 se considera completa cuando:

- [ ] Todos los 17 issues están completados
- [ ] Usuario puede hacer login con Auth0 desde frontend
- [ ] Logout flow funciona correctamente
- [ ] Token JWT se valida correctamente en backend
- [ ] Usuario se sincroniza en BD al primer login (incluyendo metadata)
- [ ] Roles y permisos funcionan correctamente
- [ ] Endpoints protegidos rechazan acceso sin permiso
- [ ] Rate limiting activo en endpoints críticos
- [ ] Audit logging registra eventos de seguridad
- [ ] Tests E2E pasan exitosamente
- [ ] Coverage de tests >= 80%
- [ ] `pnpm lint` pasa sin errores
- [ ] `pnpm build` genera build exitoso
- [ ] Seguridad auditada (sin secretos expuestos)

---

## Troubleshooting Common Issues

### Backend Issues

**Error: "Invalid signature"**
- Verificar que JWKS_URI sea correcto
- Verificar que audience e issuer coincidan
- Revisar logs de caché de JWKS

**Error: "User not found"**
- Verificar que user sync se ejecute
- Revisar que auth0_user_id sea correcto
- Verificar transacciones de BD

### Frontend Issues

**Error: "Callback URL mismatch"**
- Verificar callbacks en Auth0 dashboard
- Verificar AUTH0_BASE_URL en env vars
- Verificar que returnTo esté configurado

**Error: "Session cookie not found"**
- Verificar AUTH0_SECRET esté configurado
- Verificar cookies en DevTools
- Verificar HTTPS en producción

---

## Documentation Links

- [Auth0 Next.js SDK](https://auth0.com/docs/quickstart/webapp/nextjs)
- [NestJS Passport](https://docs.nestjs.com/security/authentication)
- [JWKS Validation](https://auth0.com/docs/secure/tokens/json-web-tokens/json-web-key-sets)
- [Role-Based Access Control](https://auth0.com/docs/manage-users/access-control/rbac)

