#!/bin/bash

# Script para crear issues de Fase 7 y Fase 8 en GitHub
# Sigue el patrón: Issue Padre + Sub-issues
# Uso: ./create-phase-7-8-issues.sh

set -e

REPO="gromeroalfonso/context-ai-api"

echo "🚀 Creando issues para Context.AI - Fases 7 y 8"
echo "================================================"
echo ""

# ============================================
# FASE 7: Testing & Quality
# ============================================

echo "🧪 FASE 7 - Testing & Quality"
echo "------------------------------"

# Issue Padre - Fase 7
gh issue create --repo "$REPO" \
  --title "Phase 7: Testing & Quality Assurance" \
  --label "phase-7-testing,epic,priority-high" \
  --body "# 🧪 Phase 7: Testing & Quality Assurance

## Objetivo
Implementar una estrategia completa de testing y QA que garantice la calidad, rendimiento, seguridad y accesibilidad del MVP de Context.AI.

## Alcance
- **Backend Testing**: Unit, Integration, E2E tests para API
- **Frontend Testing**: Component, Integration, E2E tests con Playwright
- **Performance Testing**: Load testing y optimización
- **Security Testing**: Vulnerability scanning y penetration testing
- **Accessibility Testing**: WCAG 2.1 AA compliance
- **Visual Regression**: Detección de cambios UI no intencionados
- **Smoke Tests**: Validación rápida en producción

## Sub-Issues
Esta fase se compone de 16 issues que cubren todas las áreas de testing:

### Backend Testing
- [ ] #7.1: Backend Unit Tests Optimization
- [ ] #7.2: Backend Integration Tests
- [ ] #7.3: Backend E2E Tests

### Frontend Testing  
- [ ] #7.6: Frontend Component Tests (React Testing Library)
- [ ] #7.7: Frontend E2E Tests (Playwright)
- [ ] #7.8: Frontend Integration Tests

### Performance & Load
- [ ] #7.4: Performance Testing (Backend)
- [ ] #7.9: Performance Testing (Frontend)
- [ ] #7.10: Load Testing with k6

### Quality & Coverage
- [ ] #7.5: Code Coverage & Quality Gates
- [ ] #7.11: Test Reporting Dashboard
- [ ] #7.12: Mock Data & Test Fixtures

### Advanced Testing
- [ ] #7.13: Accessibility (a11y) Testing
- [ ] #7.14: Security Testing
- [ ] #7.15: Visual Regression Testing
- [ ] #7.16: Smoke Tests for Production

## Métricas de Éxito
- ✅ Code coverage >= 80% (statements, branches, functions, lines)
- ✅ All E2E critical flows passing
- ✅ Performance targets met (API < 2s, Chat query < 5s)
- ✅ Lighthouse score >= 90 (Performance, Accessibility, Best Practices, SEO)
- ✅ Security vulnerabilities = 0 critical/high
- ✅ WCAG 2.1 AA compliance
- ✅ Visual regression tests passing
- ✅ Load testing: 100 concurrent users supported

## Estimación Total
**103 horas** (16 issues)

## Documentación
Ver: [Fase 7 - Testing Issues](../documentation/012-fase-7-testing-integration-issues.md)

## Orden de Implementación
1. Backend unit/integration tests (Issues 7.1, 7.2)
2. Frontend component tests (Issue 7.6)
3. E2E tests backend y frontend (Issues 7.3, 7.7)
4. Performance testing (Issues 7.4, 7.9, 7.10)
5. Quality gates & reporting (Issues 7.5, 7.11, 7.12)
6. Advanced testing (Issues 7.13, 7.14, 7.15, 7.16)"

echo "✅ Issue padre Fase 7 creado"

# Sub-issues Fase 7
gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.1: Optimize Backend Unit Tests" \
  --label "phase-7-testing,priority-high,backend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 6 horas

### Descripción
Revisar y optimizar los tests unitarios del backend, asegurando 80%+ coverage en todos los módulos y eliminando tests redundantes o lentos.

### Acceptance Criteria
- [ ] Coverage >= 80% en statements, branches, functions, lines
- [ ] Tests de todos los módulos: knowledge, interaction, health
- [ ] Mocks correctos de dependencias externas
- [ ] Tests aislados sin dependencias entre ellos
- [ ] Tiempos de ejecución < 30s total
- [ ] Configuración de threshold en jest.config.ts
- [ ] Documentación de estrategia de testing

### Archivos Afectados
\`\`\`
test/unit/**/*.spec.ts
jest.config.ts
package.json (scripts)
\`\`\`

**Documentación:** [Issue 7.1](../documentation/012-fase-7-testing-integration-issues.md#issue-71)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.2: Implement Backend Integration Tests" \
  --label "phase-7-testing,priority-high,backend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.1
**Estimación:** 8 horas

### Descripción
Crear suite de integration tests para el backend que validen la integración entre módulos, repositorios y servicios externos (DB, Genkit, APIs).

### Acceptance Criteria
- [ ] Tests de integración para KnowledgeModule
- [ ] Tests de integración para InteractionModule
- [ ] Tests con base de datos real (test container)
- [ ] Tests de integración con Genkit flows
- [ ] Setup/teardown de DB por test
- [ ] Fixtures de datos de prueba
- [ ] Tests aislados e idempotentes
- [ ] Tiempo ejecución < 2 min

### Archivos a Crear
\`\`\`
test/integration/modules/knowledge/knowledge-integration.spec.ts
test/integration/modules/interaction/interaction-integration.spec.ts
test/integration/genkit/flows-integration.spec.ts
test/integration/jest-setup.ts
\`\`\`

**Documentación:** [Issue 7.2](../documentation/012-fase-7-testing-integration-issues.md#issue-72)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.3: Implement Backend E2E Tests" \
  --label "phase-7-testing,priority-high,backend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.2
**Estimación:** 10 horas

### Descripción
Crear suite completa de E2E tests que validen los flujos críticos del API desde el endpoint hasta la base de datos.

### Acceptance Criteria
- [ ] Test E2E: Document Upload y Processing
- [ ] Test E2E: RAG Query Flow completo
- [ ] Test E2E: Conversation management (create, retrieve, delete)
- [ ] Test E2E: Health checks y readiness
- [ ] Test E2E: Error handling y validación
- [ ] Tests con servidor real y DB real
- [ ] Supertest para HTTP requests
- [ ] Tiempo ejecución < 5 min

### Archivos a Crear
\`\`\`
test/e2e/knowledge/document-ingestion.e2e.spec.ts
test/e2e/interaction/rag-query.e2e.spec.ts
test/e2e/interaction/conversation.e2e.spec.ts
test/e2e/health.e2e.spec.ts
\`\`\`

**Documentación:** [Issue 7.3](../documentation/012-fase-7-testing-integration-issues.md#issue-73)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.4: Implement Backend Performance Testing" \
  --label "phase-7-testing,priority-medium,backend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.3
**Estimación:** 6 horas

### Descripción
Implementar performance tests para el backend que midan tiempos de respuesta, throughput y detecten cuellos de botella.

### Acceptance Criteria
- [ ] Performance tests con Artillery o k6
- [ ] Test de Document Upload (target: < 2s)
- [ ] Test de Vector Search (target: < 1s)
- [ ] Test de RAG Query (target: < 5s LLM + 1s search)
- [ ] Test de concurrent users (10, 50, 100)
- [ ] Reports HTML generados
- [ ] Thresholds definidos y validados
- [ ] Documentación de baselines

### Archivos a Crear
\`\`\`
test/performance/document-upload.perf.ts
test/performance/rag-query.perf.ts
test/performance/vector-search.perf.ts
test/performance/k6-script.js (opcional)
\`\`\`

**Documentación:** [Issue 7.4](../documentation/012-fase-7-testing-integration-issues.md#issue-74)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.5: Configure Code Coverage & Quality Gates" \
  --label "phase-7-testing,priority-high,devops" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.1, #7.2
**Estimación:** 4 horas

### Descripción
Configurar quality gates en CI/CD que bloqueen merges si no se cumplen thresholds de coverage, linting, types y security.

### Acceptance Criteria
- [ ] Coverage thresholds configurados (80%+ en jest)
- [ ] SonarCloud o SonarQube integrado (opcional)
- [ ] GitHub Actions valida quality gates
- [ ] Lint errors bloquean CI
- [ ] Type errors bloquean CI
- [ ] Security vulnerabilities (high/critical) bloquean CI
- [ ] Reports de coverage publicados
- [ ] Badge de coverage en README

### Archivos Afectados
\`\`\`
.github/workflows/ci.yml
jest.config.ts
sonar-project.properties (opcional)
\`\`\`

**Documentación:** [Issue 7.5](../documentation/012-fase-7-testing-integration-issues.md#issue-75)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.6: Implement Frontend Component Tests" \
  --label "phase-7-testing,priority-high,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** Fase 5 completada
**Estimación:** 10 horas

### Descripción
Crear tests unitarios y de integración para todos los componentes del frontend usando React Testing Library y Jest.

### Acceptance Criteria
- [ ] Tests de ChatContainer, MessageList, MessageInput
- [ ] Tests de Navbar, Sidebar, ConversationHistory
- [ ] Tests de estado con Zustand (store mocking)
- [ ] Tests de user interactions (clicks, typing, submit)
- [ ] Tests de error states y loading states
- [ ] Coverage >= 80% en componentes
- [ ] Tests con MSW para API mocking
- [ ] Tests accesibles (queries by role/label)

### Archivos a Crear
\`\`\`
components/**/__tests__/*.test.tsx
stores/__tests__/*.test.ts
tests/utils/test-utils.tsx
tests/mocks/handlers.ts (MSW)
\`\`\`

**Documentación:** [Issue 7.6](../documentation/012-fase-7-testing-integration-issues.md#issue-76)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.7: Implement Frontend E2E Tests with Playwright" \
  --label "phase-7-testing,priority-high,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.6, Fase 6 completada
**Estimación:** 12 horas

### Descripción
Crear suite completa de E2E tests con Playwright que validen los flujos críticos del usuario en el frontend.

### Acceptance Criteria
- [ ] Test E2E: Login flow (Auth0)
- [ ] Test E2E: Send message y recibir respuesta
- [ ] Test E2E: View conversation history
- [ ] Test E2E: Create new conversation
- [ ] Test E2E: Logout flow
- [ ] Test E2E: Error handling (network, auth)
- [ ] Tests en Chrome, Firefox, Safari
- [ ] Tests responsivos (mobile, tablet, desktop)
- [ ] Screenshots y videos on failure
- [ ] Reports HTML generados

### Archivos a Crear
\`\`\`
e2e/auth/login.spec.ts
e2e/chat/send-message.spec.ts
e2e/chat/conversation-history.spec.ts
e2e/chat/new-conversation.spec.ts
playwright.config.ts
\`\`\`

**Documentación:** [Issue 7.7](../documentation/012-fase-7-testing-integration-issues.md#issue-77)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.8: Implement Frontend Integration Tests" \
  --label "phase-7-testing,priority-medium,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.6
**Estimación:** 6 horas

### Descripción
Crear tests de integración que validen la interacción entre múltiples componentes y el estado global de la aplicación.

### Acceptance Criteria
- [ ] Tests de integración Chat completo (varios componentes)
- [ ] Tests de integración Auth flow (Auth0 + routing)
- [ ] Tests de state management (Zustand actions)
- [ ] Tests de API integration (fetch + state updates)
- [ ] Tests de error boundaries
- [ ] Tests de routing (Next.js navigation)
- [ ] MSW para mocking de API
- [ ] Coverage integration >= 70%

### Archivos a Crear
\`\`\`
tests/integration/chat-flow.test.tsx
tests/integration/auth-flow.test.tsx
tests/integration/api-integration.test.tsx
\`\`\`

**Documentación:** [Issue 7.8](../documentation/012-fase-7-testing-integration-issues.md#issue-78)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.9: Implement Frontend Performance Testing" \
  --label "phase-7-testing,priority-medium,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.7
**Estimación:** 5 horas

### Descripción
Implementar tests de performance para el frontend usando Lighthouse CI y métricas Web Vitals.

### Acceptance Criteria
- [ ] Lighthouse CI configurado en GitHub Actions
- [ ] Thresholds definidos: Performance >= 90, A11y >= 90, Best Practices >= 90, SEO >= 90
- [ ] Web Vitals monitoreados (LCP, FID, CLS)
- [ ] Bundle size analysis configurado
- [ ] Tests de rendering performance
- [ ] Tests de lazy loading
- [ ] Reports automáticos en PRs
- [ ] Documentación de optimizaciones

### Archivos a Crear
\`\`\`
.github/workflows/lighthouse.yml
lighthouserc.json
tests/performance/web-vitals.test.ts
\`\`\`

**Documentación:** [Issue 7.9](../documentation/012-fase-7-testing-integration-issues.md#issue-79)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.10: Implement Load Testing with k6" \
  --label "phase-7-testing,priority-medium,backend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.4
**Estimación:** 8 horas

### Descripción
Implementar load testing completo con k6 para validar que el sistema soporte 100+ usuarios concurrent sin degradación.

### Acceptance Criteria
- [ ] k6 scripts para endpoints críticos
- [ ] Load test: Document upload (10, 50, 100 users)
- [ ] Load test: RAG query (10, 50, 100 users)
- [ ] Load test: Conversation CRUD (50 users)
- [ ] Stress test: encontrar breaking point
- [ ] Spike test: manejo de picos de tráfico
- [ ] Thresholds definidos (p95, p99, error rate)
- [ ] Reports HTML y JSON
- [ ] Documentación de resultados y optimizaciones

### Archivos a Crear
\`\`\`
test/load/k6-scripts/document-upload.js
test/load/k6-scripts/rag-query.js
test/load/k6-scripts/conversation-crud.js
test/load/k6-scripts/stress-test.js
test/load/README.md
\`\`\`

**Documentación:** [Issue 7.10](../documentation/012-fase-7-testing-integration-issues.md#issue-710)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.11: Setup Test Reporting Dashboard" \
  --label "phase-7-testing,priority-low,devops" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Baja
**Dependencias:** #7.5
**Estimación:** 5 horas

### Descripción
Configurar dashboard centralizado para visualizar resultados de todos los tests: unit, integration, E2E, performance, coverage.

### Acceptance Criteria
- [ ] Dashboard con resultados de tests (Allure, ReportPortal, o similar)
- [ ] Métricas de coverage visualizadas
- [ ] Histórico de test runs
- [ ] Integración con CI/CD
- [ ] Filtros por tipo de test, módulo, fecha
- [ ] Notificaciones de fallos
- [ ] Exportable como PDF/HTML
- [ ] Documentación de acceso

### Archivos a Crear
\`\`\`
test/reporting/allure-report.config.ts (o similar)
.github/workflows/test-reporting.yml
\`\`\`

**Documentación:** [Issue 7.11](../documentation/012-fase-7-testing-integration-issues.md#issue-711)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.12: Create Mock Data & Test Fixtures" \
  --label "phase-7-testing,priority-medium,backend,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.2, #7.6
**Estimación:** 6 horas

### Descripción
Crear biblioteca centralizada de mock data y fixtures reusables para todos los tipos de tests.

### Acceptance Criteria
- [ ] Factory functions para crear entidades de prueba
- [ ] Fixtures de JSON para API responses
- [ ] Fixtures de documentos (PDF, Markdown)
- [ ] Fixtures de embeddings (arrays 3072 dims)
- [ ] Mock de Auth0 user profiles
- [ ] MSW handlers para API mocking
- [ ] Fixtures de conversaciones y mensajes
- [ ] Documentación de uso de fixtures

### Archivos a Crear
\`\`\`
test/fixtures/entities.factory.ts
test/fixtures/documents/sample.pdf
test/fixtures/documents/sample.md
test/fixtures/api-responses/*.json
test/mocks/auth0.mock.ts
test/mocks/genkit.mock.ts
\`\`\`

**Documentación:** [Issue 7.12](../documentation/012-fase-7-testing-integration-issues.md#issue-712)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.13: Implement Accessibility (a11y) Testing" \
  --label "phase-7-testing,priority-high,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.6, #7.7
**Estimación:** 6 horas

### Descripción
Implementar suite de tests de accesibilidad usando axe-core para garantizar WCAG 2.1 AA compliance.

### Acceptance Criteria
- [ ] Tests automáticos con axe-core en componentes
- [ ] Tests de navegación por teclado (tab, enter, esc)
- [ ] Tests de lectores de pantalla (ARIA labels correctos)
- [ ] Contraste de colores validado (AA)
- [ ] Focus management verificado
- [ ] Tests E2E con Playwright axe
- [ ] Score de Lighthouse Accessibility >= 90
- [ ] Documentación de mejoras de a11y

### Archivos a Crear
\`\`\`
tests/a11y/components-a11y.test.tsx
tests/a11y/keyboard-navigation.test.tsx
e2e/a11y/accessibility.spec.ts
\`\`\`

**Documentación:** [Issue 7.13](../documentation/012-fase-7-testing-integration-issues.md#issue-713)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.14: Implement Security Testing" \
  --label "phase-7-testing,priority-high,backend,security" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.3, #7.5
**Estimación:** 8 horas

### Descripción
Crear suite de tests de seguridad para validar protección contra vulnerabilidades comunes.

### Acceptance Criteria
- [ ] Tests de SQL Injection en endpoints
- [ ] Tests de XSS en inputs (sanitización)
- [ ] Tests de CSRF protection
- [ ] Tests de JWT tampering y tokens inválidos
- [ ] Tests de rate limiting efectivo
- [ ] Tests de autorización (bypass attempts)
- [ ] Tests de input validation (edge cases)
- [ ] Security audit report generado
- [ ] OWASP Top 10 validation

### Archivos a Crear
\`\`\`
test/security/sql-injection.spec.ts
test/security/xss.spec.ts
test/security/csrf.spec.ts
test/security/jwt-security.spec.ts
test/security/rate-limiting.spec.ts
test/security/authorization.spec.ts
\`\`\`

**Documentación:** [Issue 7.14](../documentation/012-fase-7-testing-integration-issues.md#issue-714)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.15: Implement Visual Regression Testing" \
  --label "phase-7-testing,priority-medium,frontend" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Media
**Dependencias:** #7.7
**Estimación:** 5 horas

### Descripción
Implementar visual regression testing con Playwright o Percy para detectar cambios UI no intencionados.

### Acceptance Criteria
- [ ] Playwright screenshot comparisons configurado
- [ ] Screenshots baseline de páginas clave
- [ ] Tests visuales de chat, login, navbar
- [ ] Tests de responsive (mobile, tablet, desktop)
- [ ] Tests de dark mode (si aplica)
- [ ] Threshold de diff configurado (< 0.1%)
- [ ] Reports visuales de cambios
- [ ] Integración con CI/CD

### Archivos a Crear
\`\`\`
e2e/visual/chat-page.visual.spec.ts
e2e/visual/login-page.visual.spec.ts
e2e/visual/responsive.visual.spec.ts
playwright.config.ts (visual config)
\`\`\`

**Documentación:** [Issue 7.15](../documentation/012-fase-7-testing-integration-issues.md#issue-715)"

gh issue create --repo "$REPO" \
  --title "[Phase 7] 7.16: Implement Smoke Tests for Production" \
  --label "phase-7-testing,priority-high,devops" \
  --body "**Fase:** 7 - Testing & Quality
**Prioridad:** Alta
**Dependencias:** #7.3, #7.7
**Estimación:** 4 horas

### Descripción
Crear suite de smoke tests que se ejecuten post-deployment para validar que los flujos críticos funcionan en producción.

### Acceptance Criteria
- [ ] Smoke test: Health endpoint responde 200
- [ ] Smoke test: Login flow exitoso
- [ ] Smoke test: Enviar mensaje y recibir respuesta
- [ ] Smoke test: DB connectivity
- [ ] Smoke test: External APIs (Auth0, Google AI)
- [ ] Tests rápidos (< 2 min total)
- [ ] Alertas automáticas si fallan
- [ ] Ejecución post-deploy automática

### Archivos a Crear
\`\`\`
test/smoke/health.smoke.spec.ts
test/smoke/auth.smoke.spec.ts
test/smoke/chat.smoke.spec.ts
test/smoke/database.smoke.spec.ts
.github/workflows/smoke-tests.yml
\`\`\`

**Documentación:** [Issue 7.16](../documentation/012-fase-7-testing-integration-issues.md#issue-716)"

echo "✅ Fase 7 completa: 1 issue padre + 16 sub-issues"
echo ""

# ============================================
# FASE 8: Deployment & Monitoring
# ============================================

echo "🚀 FASE 8 - Deployment & Monitoring"
echo "------------------------------------"

# Issue Padre - Fase 8
gh issue create --repo "$REPO" \
  --title "Phase 8: Deployment & Monitoring" \
  --label "phase-8-deployment,epic,priority-high" \
  --body "# 🚀 Phase 8: Deployment & Monitoring

## Objetivo
Preparar y desplegar Context.AI MVP a producción con estrategias de CI/CD, monitoreo, logging, métricas, alertas y operaciones.

## Alcance
- **Containerization**: Dockerización de backend y frontend
- **CI/CD**: Pipeline completo con GitHub Actions
- **Logging**: Structured logging con Winston/Pino
- **Monitoring**: APM, métricas, health checks
- **Error Tracking**: Sentry o similar
- **Database**: Backups, migrations, disaster recovery
- **Security**: SSL/TLS, secrets management
- **Operations**: Runbooks, dashboards, alerting

## Sub-Issues
Esta fase se compone de 14 issues que cubren todo el ciclo DevOps:

### Infrastructure
- [ ] #8.1: Dockerize Backend Application
- [ ] #8.2: Dockerize Frontend Application
- [ ] #8.3: Setup CI/CD Pipeline with GitHub Actions

### Observability
- [ ] #8.4: Implement Structured Logging
- [ ] #8.5: Implement APM (Application Performance Monitoring)
- [ ] #8.6: Setup Metrics Collection and Visualization
- [ ] #8.7: Implement Error Tracking and Monitoring
- [ ] #8.13: Create Production Monitoring Dashboards

### Data & Security
- [ ] #8.8: Configure Database Backups and Disaster Recovery
- [ ] #8.9: Setup SSL/TLS Certificates and HTTPS
- [ ] #8.10: Implement Alerting and On-Call Rotation

### Operations
- [ ] #8.11: Configure Environment Management
- [ ] #8.12: Implement Performance Optimization
- [ ] #8.14: Create Operations Runbook

## Métricas de Éxito
- ✅ Build time < 5 min
- ✅ Deploy time < 10 min
- ✅ Zero-downtime deployments
- ✅ RTO (Recovery Time Objective) < 1 hour
- ✅ RPO (Recovery Point Objective) < 1 hour
- ✅ Uptime >= 99.9%
- ✅ MTTR (Mean Time To Recovery) < 30 min
- ✅ All critical alerts configured
- ✅ Logs structured and searchable
- ✅ Dashboards operacionales

## Estimación Total
**93 horas** (14 issues)

## Documentación
Ver: [Fase 8 - Deployment & Monitoring Issues](../documentation/013-fase-8-deployment-monitoring-issues.md)

## Orden de Implementación
1. Containerization (Issues 8.1, 8.2)
2. CI/CD (Issue 8.3)
3. Logging & Monitoring (Issues 8.4, 8.5, 8.6, 8.7)
4. Security & Backups (Issues 8.8, 8.9)
5. Alerting & Operations (Issues 8.10, 8.11, 8.12, 8.13, 8.14)"

echo "✅ Issue padre Fase 8 creado"

# Sub-issues Fase 8
gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.1: Dockerize Backend Application" \
  --label "phase-8-deployment,priority-high,backend" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 6 horas

### Descripción
Crear Dockerfiles optimizados para el backend con multi-stage builds, configuración de environment variables y mejores prácticas de seguridad.

### Acceptance Criteria
- [ ] Dockerfile multi-stage para backend (build + runtime)
- [ ] Imagen optimizada (< 500MB)
- [ ] Usuario non-root configurado
- [ ] Health check configurado
- [ ] Environment variables desde .env
- [ ] .dockerignore configurado
- [ ] docker-compose.yml para local dev
- [ ] Documentación de build y run
- [ ] Tests de imagen Docker

### Archivos a Crear
\`\`\`
context-ai-api/Dockerfile
context-ai-api/.dockerignore
docker-compose.dev.yml
\`\`\`

**Documentación:** [Issue 8.1](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-81)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.2: Dockerize Frontend Application" \
  --label "phase-8-deployment,priority-high,frontend" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 5 horas

### Descripción
Crear Dockerfile optimizado para el frontend Next.js con standalone output, optimización de imagen y nginx para serving.

### Acceptance Criteria
- [ ] Dockerfile multi-stage para frontend
- [ ] Next.js standalone output configurado
- [ ] Imagen optimizada (< 200MB)
- [ ] Nginx configurado para static assets
- [ ] Environment variables en build time
- [ ] .dockerignore configurado
- [ ] Health check en nginx
- [ ] Documentación de build y run

### Archivos a Crear
\`\`\`
context-ai-frontend/Dockerfile
context-ai-frontend/.dockerignore
context-ai-frontend/nginx.conf
\`\`\`

**Documentación:** [Issue 8.2](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-82)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.3: Setup CI/CD Pipeline with GitHub Actions" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.1, #8.2
**Estimación:** 10 horas

### Descripción
Configurar pipeline completo de CI/CD con GitHub Actions para lint, test, build, docker, deploy a staging y production.

### Acceptance Criteria
- [ ] Workflow de CI: lint + test + build
- [ ] Workflow de Docker: build + push a registry
- [ ] Workflow de Deploy: staging + production
- [ ] Branch protection rules configuradas
- [ ] Deploy automático a staging on merge to develop
- [ ] Deploy manual a production con approval
- [ ] Rollback strategy definida
- [ ] Secrets management con GitHub Secrets
- [ ] Notificaciones de deploy (Slack/Discord)
- [ ] Documentación de workflows

### Archivos a Crear
\`\`\`
.github/workflows/ci.yml
.github/workflows/docker-build.yml
.github/workflows/deploy-staging.yml
.github/workflows/deploy-production.yml
\`\`\`

**Documentación:** [Issue 8.3](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-83)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.4: Implement Structured Logging" \
  --label "phase-8-deployment,priority-high,backend" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 6 horas

### Descripción
Implementar structured logging en backend con Winston o Pino, incluyendo correlation IDs, log levels, y exportación a sistemas centralizados.

### Acceptance Criteria
- [ ] Winston o Pino configurado
- [ ] Logs estructurados en JSON
- [ ] Log levels: error, warn, info, debug
- [ ] Correlation ID en cada request (X-Request-ID)
- [ ] Context logging (userId, requestId, module)
- [ ] Log rotation configurado
- [ ] Exportación a stdout para Docker
- [ ] Sanitización de datos sensibles
- [ ] Documentación de logging strategy

### Archivos a Crear
\`\`\`
src/shared/infrastructure/logging/logger.service.ts
src/shared/infrastructure/logging/logger.middleware.ts
src/shared/infrastructure/logging/logger.config.ts
\`\`\`

**Documentación:** [Issue 8.4](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-84)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.5: Implement APM (Application Performance Monitoring)" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.4
**Estimación:** 8 horas

### Descripción
Integrar APM tool (New Relic, Datadog, o Elastic APM) para monitorear performance de la aplicación, detectar cuellos de botella y errores en producción.

### Acceptance Criteria
- [ ] APM agent configurado (New Relic/Datadog/Elastic)
- [ ] Métricas de performance capturadas (response time, throughput)
- [ ] Distributed tracing habilitado
- [ ] Error tracking configurado
- [ ] Custom metrics definidas (embeddings generated, queries processed)
- [ ] Dashboards configurados
- [ ] Alertas configuradas para métricas críticas
- [ ] Documentación de monitoreo

### Archivos a Crear
\`\`\`
src/shared/infrastructure/apm/apm.service.ts
src/shared/infrastructure/apm/apm.config.ts
newrelic.js (si New Relic)
\`\`\`

**Documentación:** [Issue 8.5](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-85)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.6: Setup Metrics Collection and Visualization" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.5
**Estimación:** 8 horas

### Descripción
Configurar colección de métricas custom con Prometheus y visualización con Grafana (o equivalente cloud).

### Acceptance Criteria
- [ ] Prometheus client configurado en backend
- [ ] Métricas custom: requests, errors, latency, embeddings, queries
- [ ] Métricas de sistema: CPU, RAM, disk
- [ ] Métricas de base de datos: connections, query time
- [ ] Grafana dashboards creados
- [ ] Métricas exportadas en endpoint /metrics
- [ ] Retention policy configurado
- [ ] Documentación de métricas

### Archivos a Crear
\`\`\`
src/shared/infrastructure/metrics/metrics.service.ts
src/shared/infrastructure/metrics/prometheus.config.ts
grafana/dashboards/context-ai.json
\`\`\`

**Documentación:** [Issue 8.6](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-86)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.7: Implement Error Tracking and Monitoring" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.4
**Estimación:** 6 horas

### Descripción
Integrar Sentry (o similar) para error tracking, incluyendo source maps, breadcrumbs, user context, y alertas automáticas.

### Acceptance Criteria
- [ ] Sentry configurado en backend y frontend
- [ ] Source maps subidos para stack traces legibles
- [ ] User context incluido en errores (userId, email)
- [ ] Breadcrumbs de navegación y acciones
- [ ] Release tracking configurado
- [ ] Error grouping inteligente
- [ ] Alertas configuradas (Slack/Email)
- [ ] Performance monitoring habilitado
- [ ] Documentación de error handling

### Archivos a Crear
\`\`\`
src/shared/infrastructure/error-tracking/sentry.config.ts
sentry.client.config.ts (frontend)
sentry.server.config.ts (frontend)
\`\`\`

**Documentación:** [Issue 8.7](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-87)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.8: Configure Database Backups and Disaster Recovery" \
  --label "phase-8-deployment,priority-high,backend" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 7 horas

### Descripción
Configurar estrategia completa de backups automáticos de PostgreSQL, disaster recovery, y point-in-time recovery.

### Acceptance Criteria
- [ ] Backups automáticos diarios (pg_dump)
- [ ] Backups incrementales configurados
- [ ] Backup storage en cloud (S3, GCS, Azure)
- [ ] Retention policy: 7 daily, 4 weekly, 12 monthly
- [ ] Encriptación de backups at rest
- [ ] Script de restore automatizado
- [ ] Tests de restore periódicos
- [ ] RPO < 1 hour, RTO < 1 hour
- [ ] Documentación de DR procedures

### Archivos a Crear
\`\`\`
scripts/backup/backup-database.sh
scripts/backup/restore-database.sh
.github/workflows/database-backup.yml
docs/DISASTER_RECOVERY.md
\`\`\`

**Documentación:** [Issue 8.8](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-88)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.9: Setup SSL/TLS Certificates and HTTPS" \
  --label "phase-8-deployment,priority-high,security" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Ninguna
**Estimación:** 5 horas

### Descripción
Configurar SSL/TLS certificates con Let's Encrypt o cloud provider, asegurando HTTPS en todo el tráfico.

### Acceptance Criteria
- [ ] SSL/TLS certificates configurados (Let's Encrypt)
- [ ] Auto-renewal de certificates configurado
- [ ] HTTPS enforced en frontend y backend
- [ ] HTTP redirect a HTTPS
- [ ] HSTS headers configurados
- [ ] TLS 1.2+ únicamente
- [ ] Strong cipher suites configurados
- [ ] SSL Labs rating A o A+
- [ ] Documentación de certificate management

### Archivos a Crear
\`\`\`
nginx/ssl.conf
scripts/ssl/renew-certificates.sh
.github/workflows/ssl-check.yml
\`\`\`

**Documentación:** [Issue 8.9](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-89)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.10: Implement Alerting and On-Call Rotation" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.5, #8.6, #8.7
**Estimación:** 6 hours

### Descripción
Configurar sistema de alerting para métricas críticas con escalation policy y on-call rotation (PagerDuty, Opsgenie, o similar).

### Acceptance Criteria
- [ ] Alerting tool configurado (PagerDuty/Opsgenie)
- [ ] Alertas críticas: uptime, error rate, response time
- [ ] Alertas de infra: CPU, RAM, disk, DB connections
- [ ] Escalation policy definida (15 min, 30 min, 1 hour)
- [ ] On-call rotation configurada
- [ ] Runbook links en alertas
- [ ] Notificaciones por Slack, Email, SMS
- [ ] Alert fatigue mitigation (thresholds ajustados)
- [ ] Documentación de alerting strategy

### Archivos a Crear
\`\`\`
docs/ALERTING.md
docs/ON_CALL_GUIDE.md
alerting/rules.yml
\`\`\`

**Documentación:** [Issue 8.10](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-810)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.11: Configure Environment Management" \
  --label "phase-8-deployment,priority-medium,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Media
**Dependencias:** #8.3
**Estimación:** 5 horas

### Descripción
Configurar gestión de múltiples environments (dev, staging, production) con secrets management, config per environment, y segregación.

### Acceptance Criteria
- [ ] Environments definidos: dev, staging, production
- [ ] Secrets management con GitHub Secrets o Vault
- [ ] .env files per environment
- [ ] Environment-specific configs (database, APIs, features)
- [ ] Feature flags configurados (opcional)
- [ ] Access control per environment
- [ ] Deployment gates (staging -> production)
- [ ] Documentación de environment strategy

### Archivos a Crear
\`\`\`
.env.development
.env.staging
.env.production
docs/ENVIRONMENT_MANAGEMENT.md
\`\`\`

**Documentación:** [Issue 8.11](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-811)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.12: Implement Performance Optimization" \
  --label "phase-8-deployment,priority-medium,backend,frontend" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Media
**Dependencias:** #8.5, #8.6
**Estimación:** 10 horas

### Descripción
Implementar optimizaciones de performance basadas en métricas reales: caching, CDN, database query optimization, bundle size reduction.

### Acceptance Criteria
- [ ] Redis caching para queries frecuentes
- [ ] CDN configurado para static assets
- [ ] Database indexes optimizados
- [ ] Connection pooling configurado
- [ ] Frontend bundle size optimizado (< 200KB)
- [ ] Image optimization con Next.js Image
- [ ] API response compression (gzip/brotli)
- [ ] Lazy loading configurado
- [ ] Performance metrics mejoradas en 20%+
- [ ] Documentación de optimizaciones

### Archivos a Crear
\`\`\`
src/shared/infrastructure/cache/redis.service.ts
src/shared/infrastructure/cache/cache.config.ts
docs/PERFORMANCE_OPTIMIZATION.md
\`\`\`

**Documentación:** [Issue 8.12](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-812)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.13: Create Production Monitoring Dashboards" \
  --label "phase-8-deployment,priority-high,devops" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** #8.5, #8.6
**Estimación:** 6 horas

### Descripción
Crear dashboards completos en Grafana (o similar) para visualizar salud del sistema, métricas de negocio, y KPIs operacionales.

### Acceptance Criteria
- [ ] Dashboard de salud del sistema (uptime, errors, latency)
- [ ] Dashboard de métricas de negocio (queries, users, conversations)
- [ ] Dashboard de infraestructura (CPU, RAM, disk, network)
- [ ] Dashboard de database (connections, queries, slow queries)
- [ ] Dashboard de costos (API calls, embeddings, tokens)
- [ ] Dashboards públicos para status page
- [ ] Auto-refresh configurado
- [ ] Documentación de dashboards

### Archivos a Crear
\`\`\`
grafana/dashboards/system-health.json
grafana/dashboards/business-metrics.json
grafana/dashboards/infrastructure.json
grafana/dashboards/database.json
\`\`\`

**Documentación:** [Issue 8.13](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-813)"

gh issue create --repo "$REPO" \
  --title "[Phase 8] 8.14: Create Operations Runbook" \
  --label "phase-8-deployment,priority-high,documentation" \
  --body "**Fase:** 8 - Deployment & Monitoring
**Prioridad:** Alta
**Dependencias:** Todos los anteriores de Fase 8
**Estimación:** 8 horas

### Descripción
Crear runbook completo de operaciones con procedimientos para incidentes comunes, troubleshooting, y maintenance.

### Acceptance Criteria
- [ ] Runbook de incidents: high error rate, slow queries, out of memory
- [ ] Runbook de deployments: rollback, hotfix, emergency patch
- [ ] Runbook de maintenance: DB migrations, backups restore
- [ ] Runbook de scaling: horizontal scaling, vertical scaling
- [ ] Troubleshooting guides: logs, metrics, tracing
- [ ] Contact information y escalation paths
- [ ] Links a dashboards, logs, APM
- [ ] Post-mortem template
- [ ] Documentación clara y actualizada

### Archivos a Crear
\`\`\`
docs/RUNBOOK.md
docs/TROUBLESHOOTING.md
docs/INCIDENT_RESPONSE.md
docs/POST_MORTEM_TEMPLATE.md
\`\`\`

**Documentación:** [Issue 8.14](../documentation/013-fase-8-deployment-monitoring-issues.md#issue-814)"

echo "✅ Fase 8 completa: 1 issue padre + 14 sub-issues"
echo ""

echo "================================================"
echo "✅ CREACIÓN COMPLETA"
echo "================================================"
echo ""
echo "📊 Resumen:"
echo "  - Fase 7: 1 padre + 16 sub-issues = 17 issues"
echo "  - Fase 8: 1 padre + 14 sub-issues = 15 issues"
echo "  - TOTAL: 32 issues creados"
echo ""
echo "🔗 Ver en: https://github.com/$REPO/issues"
echo "📋 Ver en: https://github.com/$REPO/projects"
echo ""
echo "✅ Siguiente paso: Organizar en GitHub Projects"
echo "================================================"

