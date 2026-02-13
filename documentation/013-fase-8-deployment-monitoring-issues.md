---
name: Fase 8 - Deployment y Monitoring
overview: "Descomposición de la Fase 8 del MVP en issues granulares para implementar deployment a producción, configuración de infraestructura, monitoring, observabilidad, logging estructurado y alerting. Incluye Docker, CI/CD, métricas de negocio y documentación operacional."
phase: 8
parent_phase: "009-plan-implementacion-detallado.md"
total_issues: 14
---

# Fase 8: Deployment y Monitoring

Descomposición en issues manejables para desplegar el MVP a producción y configurar monitoring/observabilidad completos.

---

## Issue 8.1: Dockerize Backend Application

**Prioridad:** Alta  
**Dependencias:** Ninguna  
**Estimación:** 6 horas

### Descripción

Crear Dockerfiles optimizados para el backend con multi-stage builds, configuración de environment variables y mejores prácticas de seguridad.

### Acceptance Criteria

- [ ] Dockerfile multi-stage para backend
- [ ] Imagen optimizada (< 500MB)
- [ ] No ejecuta como root
- [ ] Health check configurado
- [ ] Environment variables desde .env
- [ ] .dockerignore configurado
- [ ] Documentación de build y run
- [ ] Tests de imagen Docker

### Files to Create

```
context-ai-api/Dockerfile                     # Dockerfile principal
context-ai-api/.dockerignore                  # Ignore patterns
context-ai-api/docker-compose.prod.yml        # Compose para prod
context-ai-api/scripts/docker-build.sh        # Script de build
context-ai-api/docs/DOCKER_SETUP.md           # Documentación
```

### Technical Notes

```dockerfile
# Dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application
RUN pnpm build

# Stage 2: Production
FROM node:20-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Change ownership
RUN chown -R nestjs:nodejs /app

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "dist/main.js"]
```

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - GOOGLE_API_KEY=${GOOGLE_API_KEY}
      - AUTH0_DOMAIN=${AUTH0_DOMAIN}
      - AUTH0_AUDIENCE=${AUTH0_AUDIENCE}
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3000/health']
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER}']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local
```

---

## Issue 8.2: Dockerize Frontend Application

**Prioridad:** Alta  
**Dependencias:** Ninguna  
**Estimación:** 5 horas

### Descripción

Crear Dockerfile para Next.js con standalone output optimizado para producción y configuración de nginx reverse proxy.

### Acceptance Criteria

- [ ] Dockerfile multi-stage para Next.js
- [ ] Standalone output configurado
- [ ] Imagen optimizada (< 300MB)
- [ ] Environment variables en runtime
- [ ] nginx configurado como reverse proxy
- [ ] Compresión gzip habilitada
- [ ] Documentación de deployment
- [ ] Tests de imagen Docker

### Files to Create

```
context-ai-front/Dockerfile                   # Dockerfile principal
context-ai-front/.dockerignore                # Ignore patterns
context-ai-front/nginx.conf                   # Configuración nginx
context-ai-front/next.config.js               # Config (actualizar)
context-ai-front/docs/DOCKER_DEPLOYMENT.md    # Documentación
```

### Technical Notes

```dockerfile
# Dockerfile
FROM node:20-alpine AS base

# Install pnpm
RUN npm install -g pnpm

# Stage 1: Dependencies
FROM base AS deps

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Stage 2: Builder
FROM base AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED 1

# Build application
RUN pnpm build

# Stage 3: Runner
FROM base AS runner

WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy necessary files
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

```javascript
// next.config.js
module.exports = {
  output: 'standalone',
  // ... other config
};
```

```nginx
# nginx.conf
upstream nextjs {
    server frontend:3000;
}

server {
    listen 80;
    server_name contextai.com www.contextai.com;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    location / {
        proxy_pass http://nextjs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Issue 8.3: Configure CI/CD Pipeline for Deployment

**Prioridad:** Alta  
**Dependencias:** 8.1, 8.2  
**Estimación:** 8 horas

### Descripción

Configurar CI/CD pipeline completo con GitHub Actions para build, test, security scan y deployment automático a staging y producción.

### Acceptance Criteria

- [ ] Pipeline de CI/CD con GitHub Actions
- [ ] Build automático en push a develop/main
- [ ] Tests automáticos (lint, unit, integration, e2e)
- [ ] Security scanning (Snyk, CodeQL)
- [ ] Build de imágenes Docker
- [ ] Push a Docker Hub/GitHub Container Registry
- [ ] Deployment automático a staging
- [ ] Deployment manual a producción (approval)
- [ ] Rollback strategy configurado

### Files to Create

```
.github/workflows/deploy-staging.yml          # Deploy a staging
.github/workflows/deploy-production.yml       # Deploy a prod
.github/workflows/docker-build.yml            # Build Docker images
scripts/deploy.sh                             # Script de deployment
docs/CI_CD_PIPELINE.md                        # Documentación
```

### Technical Notes

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  workflow_dispatch:  # Manual trigger only
    inputs:
      version:
        description: 'Version to deploy'
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://contextai.com
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8
      
      # Run all tests before deployment
      - name: Run Backend Tests
        run: |
          cd context-ai-api
          pnpm install
          pnpm lint
          pnpm test:all
          pnpm build
      
      - name: Run Frontend Tests
        run: |
          cd context-ai-front
          pnpm install
          pnpm lint
          pnpm test
          pnpm build
      
      # Build Docker images
      - name: Build and Push Docker Images
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          
          # Backend
          docker build -t contextai/api:${{ github.event.inputs.version }} ./context-ai-api
          docker push contextai/api:${{ github.event.inputs.version }}
          
          # Frontend
          docker build -t contextai/frontend:${{ github.event.inputs.version }} ./context-ai-front
          docker push contextai/frontend:${{ github.event.inputs.version }}
      
      # Deploy to production
      - name: Deploy to Production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /opt/contextai
            export VERSION=${{ github.event.inputs.version }}
            docker-compose pull
            docker-compose up -d
            docker-compose ps
      
      # Run smoke tests
      - name: Run Smoke Tests
        run: |
          sleep 30  # Wait for services to start
          cd context-ai-api
          pnpm test:smoke
        env:
          API_URL: https://api.contextai.com
          SMOKE_TEST_TOKEN: ${{ secrets.PROD_SMOKE_TEST_TOKEN }}
      
      # Notify deployment
      - name: Notify Deployment
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ Production deployment successful - Version: ${{ github.event.inputs.version }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Issue 8.4: Implement Structured Logging

**Prioridad:** Alta  
**Dependencias:** 8.1  
**Estimación:** 6 horas

### Descripción

Implementar logging estructurado con Winston o Pino para facilitar debugging, monitoring y análisis de logs en producción.

### Acceptance Criteria

- [ ] Logger configurado (Winston o Pino)
- [ ] Logs estructurados en formato JSON
- [ ] Niveles de log configurables por environment
- [ ] Context y correlation IDs en logs
- [ ] Logs de requests HTTP (middleware)
- [ ] Logs de errores con stack traces
- [ ] Rotación de logs configurada
- [ ] Integration con servicio de logs (opcional)

### Files to Create

```
src/common/logger/logger.module.ts            # Módulo de logger
src/common/logger/logger.service.ts           # Servicio
src/common/middleware/request-logger.middleware.ts  # Middleware
src/common/interceptors/logging.interceptor.ts  # Interceptor
config/logger.config.ts                       # Configuración
```

### Technical Notes

```typescript
// logger.service.ts
import { Injectable, LoggerService } from '@nestjs/common';
import * as winston from 'winston';

@Injectable()
export class CustomLoggerService implements LoggerService {
  private logger: winston.Logger;

  constructor() {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json(),
      ),
      defaultMeta: {
        service: 'context-ai-api',
        environment: process.env.NODE_ENV,
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple(),
          ),
        }),
        new winston.transports.File({
          filename: 'logs/error.log',
          level: 'error',
          maxsize: 5242880, // 5MB
          maxFiles: 5,
        }),
        new winston.transports.File({
          filename: 'logs/combined.log',
          maxsize: 5242880,
          maxFiles: 5,
        }),
      ],
    });
  }

  log(message: string, context?: string, meta?: Record<string, any>) {
    this.logger.info(message, { context, ...meta });
  }

  error(message: string, trace?: string, context?: string, meta?: Record<string, any>) {
    this.logger.error(message, { trace, context, ...meta });
  }

  warn(message: string, context?: string, meta?: Record<string, any>) {
    this.logger.warn(message, { context, ...meta });
  }

  debug(message: string, context?: string, meta?: Record<string, any>) {
    this.logger.debug(message, { context, ...meta });
  }
}

// request-logger.middleware.ts
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { CustomLoggerService } from '../logger/logger.service';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  constructor(private logger: CustomLoggerService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const correlationId = uuidv4();
    req['correlationId'] = correlationId;

    const startTime = Date.now();

    res.on('finish', () => {
      const duration = Date.now() - startTime;
      
      this.logger.log('HTTP Request', 'HTTP', {
        correlationId,
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        duration,
        userAgent: req.headers['user-agent'],
        ip: req.ip,
      });
    });

    next();
  }
}

// Dependencias
pnpm add winston
pnpm add -D @types/winston
```

---

## Issue 8.5: Implement APM (Application Performance Monitoring)

**Prioridad:** Alta  
**Dependencias:** 8.4  
**Estimación:** 8 horas

### Descripción

Integrar APM tool (New Relic, Datadog o self-hosted) para monitorear performance de la aplicación, detectar cuellos de botella y errores en producción.

### Acceptance Criteria

- [ ] APM agent configurado (New Relic o Datadog)
- [ ] Métricas de performance capturadas
- [ ] Distributed tracing habilitado
- [ ] Error tracking configurado
- [ ] Custom metrics definidas
- [ ] Dashboards configurados
- [ ] Alertas configuradas para métricas críticas
- [ ] Documentación de monitoreo

### Files to Create

```
src/common/apm/apm.module.ts                  # Módulo APM
src/common/apm/apm.service.ts                 # Servicio
src/common/interceptors/performance.interceptor.ts  # Interceptor
config/apm.config.ts                          # Configuración
docs/APM_SETUP.md                             # Documentación
```

### Technical Notes

```typescript
// apm.service.ts
import { Injectable } from '@nestjs/common';
import * as newrelic from 'newrelic'; // or datadog

@Injectable()
export class ApmService {
  trackCustomMetric(name: string, value: number) {
    newrelic.recordMetric(name, value);
  }

  trackBusinessEvent(eventName: string, attributes: Record<string, any>) {
    newrelic.recordCustomEvent(eventName, attributes);
  }

  startTransaction(name: string, type: string = 'web') {
    return newrelic.startWebTransaction(name, () => {
      // Transaction logic
    });
  }

  noticeError(error: Error, customAttributes?: Record<string, any>) {
    newrelic.noticeError(error, customAttributes);
  }

  addCustomAttribute(key: string, value: string | number) {
    newrelic.addCustomAttribute(key, value);
  }
}

// performance.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApmService } from '../apm/apm.service';

@Injectable()
export class PerformanceInterceptor implements NestInterceptor {
  constructor(private apmService: ApmService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const endpoint = `${request.method} ${request.route?.path}`;
    
    const startTime = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - startTime;
        
        // Track endpoint performance
        this.apmService.trackCustomMetric(`endpoint.${endpoint}.duration`, duration);
        
        // Track business metrics
        if (endpoint.includes('/chat/query')) {
          this.apmService.trackBusinessEvent('ChatQuery', {
            duration,
            userId: request.user?.id,
            sectorId: request.body.sectorId,
          });
        }
      }),
    );
  }
}

// Dependencias
// New Relic
pnpm add newrelic

// O Datadog
pnpm add dd-trace
```

---

## Issue 8.6: Implement Metrics with Prometheus

**Prioridad:** Media  
**Dependencias:** 8.4  
**Estimación:** 6 horas

### Descripción

Configurar Prometheus para recolectar métricas técnicas y de negocio, con exportación de métricas custom y dashboards en Grafana.

### Acceptance Criteria

- [ ] Prometheus client configurado
- [ ] Métricas técnicas (CPU, memoria, requests)
- [ ] Métricas de negocio (queries, users, documents)
- [ ] Endpoint /metrics expuesto
- [ ] Grafana configurado con dashboards
- [ ] Métricas custom por módulo
- [ ] Alerting rules definidas
- [ ] Documentación de métricas

### Files to Create

```
src/common/metrics/metrics.module.ts          # Módulo de métricas
src/common/metrics/metrics.service.ts         # Servicio
config/prometheus.yml                         # Config Prometheus
config/grafana-dashboards/api-dashboard.json  # Dashboard
docs/METRICS_GUIDE.md                         # Documentación
```

### Technical Notes

```typescript
// metrics.service.ts
import { Injectable } from '@nestjs/common';
import { Counter, Histogram, Gauge, register } from 'prom-client';

@Injectable()
export class MetricsService {
  private httpRequestDuration: Histogram;
  private httpRequestTotal: Counter;
  private activeChatSessions: Gauge;
  private documentsProcessed: Counter;

  constructor() {
    // HTTP metrics
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'Duration of HTTP requests in seconds',
      labelNames: ['method', 'route', 'status'],
    });

    this.httpRequestTotal = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status'],
    });

    // Business metrics
    this.activeChatSessions = new Gauge({
      name: 'active_chat_sessions',
      help: 'Number of active chat sessions',
    });

    this.documentsProcessed = new Counter({
      name: 'documents_processed_total',
      help: 'Total number of documents processed',
      labelNames: ['sector', 'status'],
    });
  }

  recordHttpRequest(method: string, route: string, status: number, duration: number) {
    this.httpRequestDuration.labels(method, route, status.toString()).observe(duration);
    this.httpRequestTotal.labels(method, route, status.toString()).inc();
  }

  incrementActiveSessions() {
    this.activeChatSessions.inc();
  }

  decrementActiveSessions() {
    this.activeChatSessions.dec();
  }

  recordDocumentProcessed(sector: string, status: 'success' | 'failed') {
    this.documentsProcessed.labels(sector, status).inc();
  }

  getMetrics(): Promise<string> {
    return register.metrics();
  }
}

// metrics.controller.ts
import { Controller, Get } from '@nestjs/common';
import { MetricsService } from './metrics.service';

@Controller('metrics')
export class MetricsController {
  constructor(private metricsService: MetricsService) {}

  @Get()
  async getMetrics() {
    return this.metricsService.getMetrics();
  }
}

// Dependencias
pnpm add prom-client
```

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - '9090:9090'
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - '3001:3000'
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana-dashboards:/etc/grafana/provisioning/dashboards
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

---

## Issue 8.7: Implement Error Tracking with Sentry

**Prioridad:** Alta  
**Dependencias:** 8.1, 8.2  
**Estimación:** 4 horas

### Descripción

Integrar Sentry para tracking automático de errores en backend y frontend con contexto completo, sourcemaps y alerting.

### Acceptance Criteria

- [ ] Sentry configurado en backend
- [ ] Sentry configurado en frontend
- [ ] Sourcemaps subidos automáticamente
- [ ] Contexto de usuario capturado
- [ ] Breadcrumbs habilitados
- [ ] Alertas configuradas para errores críticos
- [ ] Performance monitoring habilitado
- [ ] Documentación de error tracking

### Files to Create

```
context-ai-api/src/config/sentry.config.ts    # Config backend
context-ai-front/lib/sentry.config.ts         # Config frontend
.github/workflows/upload-sourcemaps.yml       # Workflow
docs/ERROR_TRACKING.md                        # Documentación
```

### Technical Notes

```typescript
// Backend - src/config/sentry.config.ts
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

export function initSentry() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV,
    integrations: [
      new ProfilingIntegration(),
    ],
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    profilesSampleRate: 0.1,
    beforeSend(event, hint) {
      // Filter out sensitive data
      if (event.request) {
        delete event.request.cookies;
        delete event.request.headers?.authorization;
      }
      return event;
    },
  });
}

// main.ts
import { initSentry } from './config/sentry.config';

async function bootstrap() {
  initSentry();
  
  const app = await NestFactory.create(AppModule);
  // ...
}

// Frontend - lib/sentry.config.ts
import * as Sentry from '@sentry/nextjs';

export function initSentry() {
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
    environment: process.env.NEXT_PUBLIC_ENV,
    tracesSampleRate: 0.1,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
    integrations: [
      new Sentry.Replay({
        maskAllText: false,
        blockAllMedia: false,
      }),
    ],
  });
}

// Dependencias
pnpm add @sentry/node @sentry/profiling-node  # Backend
pnpm add @sentry/nextjs                       # Frontend
```

---

## Issue 8.8: Configure Database Backups

**Prioridad:** Alta  
**Dependencias:** 8.3  
**Estimación:** 5 horas

### Descripción

Configurar backup automático de PostgreSQL con retención policy, restauración documentada y testing de backups.

### Acceptance Criteria

- [ ] Backup automático diario configurado
- [ ] Backup incremental cada hora
- [ ] Retención policy definida (30 días)
- [ ] Backups encriptados
- [ ] Storage en S3 o similar
- [ ] Script de restauración documentado
- [ ] Tests de restauración periódicos
- [ ] Alertas si backup falla

### Files to Create

```
scripts/backup-database.sh                    # Script de backup
scripts/restore-database.sh                   # Script de restauración
scripts/test-backup-restore.sh                # Test de restauración
.github/workflows/database-backup.yml         # Workflow
docs/BACKUP_RESTORE.md                        # Documentación
```

### Technical Notes

```bash
#!/bin/bash
# scripts/backup-database.sh

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgresql"
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Encrypt backup
openssl enc -aes-256-cbc -salt -in $BACKUP_FILE -out $BACKUP_FILE.enc -pass pass:$BACKUP_PASSWORD

# Upload to S3
aws s3 cp $BACKUP_FILE.enc s3://$S3_BUCKET/backups/postgresql/

# Cleanup old backups (keep last 30 days)
find $BACKUP_DIR -name "backup_*.sql.gz.enc" -mtime +30 -delete

# Verify backup
if [ -f "$BACKUP_FILE.enc" ]; then
  echo "✅ Backup successful: $BACKUP_FILE.enc"
else
  echo "❌ Backup failed!"
  # Send alert
  curl -X POST $SLACK_WEBHOOK_URL -d '{"text":"🚨 Database backup failed!"}'
  exit 1
fi
```

```yaml
# .github/workflows/database-backup.yml
name: Database Backup

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Database Backup
        run: ./scripts/backup-database.sh
        env:
          DB_HOST: ${{ secrets.DB_HOST }}
          DB_USER: ${{ secrets.DB_USER }}
          DB_NAME: ${{ secrets.DB_NAME }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
          BACKUP_PASSWORD: ${{ secrets.BACKUP_PASSWORD }}
          S3_BUCKET: ${{ secrets.S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

---

## Issue 8.9: Configure SSL/TLS and HTTPS

**Prioridad:** Alta  
**Dependencias:** 8.3  
**Estimación:** 4 horas

### Descripción

Configurar SSL/TLS certificates con Let's Encrypt, HTTPS redirect y security headers para producción.

### Acceptance Criteria

- [ ] SSL certificates configurados con Let's Encrypt
- [ ] Auto-renewal configurado con certbot
- [ ] HTTP to HTTPS redirect
- [ ] Security headers configurados (HSTS, CSP, etc.)
- [ ] SSL Labs score A+
- [ ] Nginx configurado como reverse proxy
- [ ] Documentación de renovación de certs
- [ ] Tests de HTTPS

### Files to Create

```
config/nginx/nginx-ssl.conf                   # Nginx con SSL
scripts/setup-ssl.sh                          # Setup SSL
scripts/renew-ssl.sh                          # Renovación SSL
docs/SSL_SETUP.md                             # Documentación
```

### Technical Notes

```nginx
# nginx-ssl.conf
server {
    listen 80;
    server_name contextai.com www.contextai.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name contextai.com www.contextai.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/contextai.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/contextai.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

    # Gzip Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location / {
        proxy_pass http://frontend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://api:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# scripts/setup-ssl.sh
#!/bin/bash

# Install certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Obtain certificate
certbot --nginx -d contextai.com -d www.contextai.com \
  --email admin@contextai.com \
  --agree-tos \
  --non-interactive

# Setup auto-renewal
echo "0 0 * * * root certbot renew --quiet" >> /etc/crontab

# Test renewal
certbot renew --dry-run

echo "✅ SSL setup complete!"
```

---

## Issue 8.10: Implement Alerting System

**Prioridad:** Alta  
**Dependencias:** 8.5, 8.6  
**Estimación:** 6 horas

### Descripción

Configurar sistema de alerting para eventos críticos con múltiples canales (Slack, email, PagerDuty) y escalation policies.

### Acceptance Criteria

- [ ] Alertas configuradas para errores críticos
- [ ] Alertas de performance (latencia alta)
- [ ] Alertas de disponibilidad (downtime)
- [ ] Alertas de seguridad (rate limit exceeded)
- [ ] Integración con Slack
- [ ] Integración con email
- [ ] PagerDuty para on-call (opcional)
- [ ] Documentación de alertas

### Files to Create

```
src/common/alerts/alerts.module.ts            # Módulo de alertas
src/common/alerts/alerts.service.ts           # Servicio
config/alert-rules.yml                        # Reglas de alertas
docs/ALERTING_GUIDE.md                        # Documentación
```

### Technical Notes

```typescript
// alerts.service.ts
import { Injectable } from '@nestjs/common';
import axios from 'axios';

export enum AlertSeverity {
  INFO = 'info',
  WARNING = 'warning',
  CRITICAL = 'critical',
}

@Injectable()
export class AlertsService {
  async sendAlert(
    title: string,
    message: string,
    severity: AlertSeverity = AlertSeverity.INFO,
  ) {
    // Send to Slack
    await this.sendToSlack(title, message, severity);

    // Send email for critical alerts
    if (severity === AlertSeverity.CRITICAL) {
      await this.sendEmail(title, message);
    }

    // Log alert
    console.log(`[ALERT] ${severity.toUpperCase()}: ${title} - ${message}`);
  }

  private async sendToSlack(title: string, message: string, severity: AlertSeverity) {
    const emoji = severity === AlertSeverity.CRITICAL ? '🚨' : 
                  severity === AlertSeverity.WARNING ? '⚠️' : 'ℹ️';

    await axios.post(process.env.SLACK_WEBHOOK_URL || '', {
      text: `${emoji} *${title}*\n${message}`,
      username: 'Context.AI Alerts',
    });
  }

  private async sendEmail(title: string, message: string) {
    // Implement email sending logic
    console.log(`Sending email alert: ${title}`);
  }
}

// Uso en error handling
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private alertsService: AlertsService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    // ...
    
    if (exception instanceof CriticalError) {
      this.alertsService.sendAlert(
        'Critical Error in Production',
        `Error: ${exception.message}\nStack: ${exception.stack}`,
        AlertSeverity.CRITICAL,
      );
    }
  }
}
```

```yaml
# config/alert-rules.yml
alerts:
  - name: HighErrorRate
    condition: error_rate > 5%
    duration: 5m
    severity: critical
    message: "Error rate is above 5% for the last 5 minutes"

  - name: HighLatency
    condition: p95_latency > 3s
    duration: 10m
    severity: warning
    message: "95th percentile latency is above 3 seconds"

  - name: ServiceDown
    condition: uptime < 99%
    duration: 2m
    severity: critical
    message: "Service availability is below 99%"

  - name: DatabaseConnectionIssue
    condition: db_connection_errors > 10
    duration: 5m
    severity: critical
    message: "Multiple database connection errors detected"
```

---

## Issue 8.11: Configure Environment Management

**Prioridad:** Alta  
**Dependencias:** 8.3  
**Estimación:** 5 horas

### Descripción

Configurar gestión de environments (dev, staging, production) con variables de entorno seguras y secrets management.

### Acceptance Criteria

- [ ] Configuración separada por environment
- [ ] Secrets management con GitHub Secrets o Vault
- [ ] .env files no committeados en git
- [ ] .env.example templates actualizados
- [ ] Variables de entorno documentadas
- [ ] Validación de variables requeridas al inicio
- [ ] Rotation policy para secrets
- [ ] Documentación de configuración

### Files to Create

```
.env.example                                  # Template (actualizar)
.env.development                              # Dev (no commited)
.env.staging                                  # Staging (no commited)
.env.production                               # Prod (no commited)
src/config/env-validation.ts                  # Validación
docs/ENVIRONMENT_SETUP.md                     # Documentación
```

### Technical Notes

```typescript
// env-validation.ts
import { plainToClass } from 'class-transformer';
import { IsString, IsNumber, IsUrl, validateSync } from 'class-validator';

class EnvironmentVariables {
  @IsString()
  NODE_ENV: string;

  @IsNumber()
  PORT: number;

  @IsUrl({ require_tld: false })
  DATABASE_URL: string;

  @IsString()
  GOOGLE_API_KEY: string;

  @IsString()
  AUTH0_DOMAIN: string;

  @IsString()
  AUTH0_AUDIENCE: string;

  @IsString()
  SENTRY_DSN: string;
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToClass(
    EnvironmentVariables,
    config,
    { enableImplicitConversion: true },
  );

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Environment validation failed:\n${errors.toString()}`);
  }

  return validatedConfig;
}
```

```bash
# .env.example
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/contextai
DB_HOST=localhost
DB_PORT=5432
DB_NAME=contextai
DB_USER=user
DB_PASSWORD=password

# Google AI
GOOGLE_API_KEY=your_google_api_key_here

# Auth0
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_AUDIENCE=https://api.contextai.com
AUTH0_ISSUER_BASE_URL=https://your-tenant.auth0.com/

# Monitoring
SENTRY_DSN=your_sentry_dsn_here
NEW_RELIC_LICENSE_KEY=your_newrelic_key_here

# Logging
LOG_LEVEL=info

# Security
JWT_SECRET=your_jwt_secret_here
ENCRYPTION_KEY=your_encryption_key_here

# External Services
SLACK_WEBHOOK_URL=your_slack_webhook_url
```

---

## Issue 8.12: Implement Performance Optimization

**Prioridad:** Media  
**Dependencias:** 8.6  
**Estimación:** 6 horas

### Descripción

Optimizar performance de producción con caching, CDN, database indexing y query optimization.

### Acceptance Criteria

- [ ] Redis configurado para caching
- [ ] CDN configurado para assets estáticos
- [ ] Database queries optimizadas
- [ ] Índices de BD apropiados
- [ ] Response caching implementado
- [ ] Compression habilitada
- [ ] Performance metrics mejoradas
- [ ] Documentación de optimizaciones

### Files to Create

```
src/common/cache/cache.module.ts              # Módulo de cache
src/common/cache/cache.service.ts             # Servicio
config/redis.config.ts                        # Configuración Redis
scripts/analyze-queries.sql                   # Análisis de queries
docs/PERFORMANCE_OPTIMIZATION.md              # Documentación
```

### Technical Notes

```typescript
// cache.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class CacheService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  async get<T>(key: string): Promise<T | undefined> {
    return await this.cacheManager.get<T>(key);
  }

  async set(key: string, value: any, ttl?: number): Promise<void> {
    await this.cacheManager.set(key, value, ttl);
  }

  async del(key: string): Promise<void> {
    await this.cacheManager.del(key);
  }

  // Cache decorator
  async wrap<T>(
    key: string,
    fn: () => Promise<T>,
    ttl?: number,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached) return cached;

    const result = await fn();
    await this.set(key, result, ttl);
    return result;
  }
}

// Uso en servicios
@Injectable()
export class KnowledgeService {
  constructor(private cacheService: CacheService) {}

  async getSources(sectorId: string) {
    return this.cacheService.wrap(
      `sources:${sectorId}`,
      async () => {
        return this.repository.find({ where: { sectorId } });
      },
      3600, // Cache for 1 hour
    );
  }
}

// app.module.ts
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';

@Module({
  imports: [
    CacheModule.register({
      isGlobal: true,
      store: redisStore,
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
      ttl: 600, // 10 minutes default
    }),
  ],
})
export class AppModule {}

// Dependencias
pnpm add @nestjs/cache-manager cache-manager cache-manager-redis-store redis
```

---

## Issue 8.13: Create Operations Runbook

**Prioridad:** Media  
**Dependencias:** Todas las anteriores  
**Estimación:** 8 horas

### Descripción

Crear runbook completo para operaciones incluyendo deployment, troubleshooting, disaster recovery y common issues.

### Acceptance Criteria

- [ ] Deployment procedures documentadas
- [ ] Rollback procedures documentadas
- [ ] Troubleshooting guide completo
- [ ] Common issues y soluciones
- [ ] Disaster recovery plan
- [ ] On-call procedures
- [ ] Architecture diagrams actualizados
- [ ] Contact information actualizada

### Files to Create

```
docs/ops/RUNBOOK.md                           # Runbook principal
docs/ops/DEPLOYMENT.md                        # Deployment guide
docs/ops/TROUBLESHOOTING.md                   # Troubleshooting
docs/ops/DISASTER_RECOVERY.md                 # DR plan
docs/ops/COMMON_ISSUES.md                     # Issues comunes
docs/ops/ON_CALL_GUIDE.md                     # On-call guide
docs/ARCHITECTURE.md                          # Actualizado
```

### Technical Notes

```markdown
# RUNBOOK.md

## Quick Links
- **Application:** https://contextai.com
- **API:** https://api.contextai.com
- **Monitoring:** https://grafana.contextai.com
- **Logs:** https://kibana.contextai.com
- **APM:** https://newrelic.com/...
- **Errors:** https://sentry.io/...

## System Architecture

[Diagrama de arquitectura actualizado]

## Common Operations

### 1. Deploy to Production

```bash
# Trigger via GitHub Actions
gh workflow run deploy-production.yml -f version=1.2.3

# Or manually
./scripts/deploy.sh production 1.2.3
```

### 2. Rollback Deployment

```bash
# Rollback to previous version
./scripts/rollback.sh production 1.2.2
```

### 3. Check System Health

```bash
# Health check
curl https://api.contextai.com/health

# Metrics
curl https://api.contextai.com/metrics

# Smoke tests
pnpm test:smoke
```

### 4. Database Operations

```bash
# Backup
./scripts/backup-database.sh

# Restore
./scripts/restore-database.sh backup_20240207_120000.sql.gz.enc

# Migrations
pnpm migration:run
```

## Incident Response

### 1. Service Down
1. Check health endpoint
2. Check logs in Kibana
3. Check APM in New Relic
4. Check recent deployments
5. Rollback if needed

### 2. High Error Rate
1. Check Sentry for error details
2. Check APM for slow queries
3. Check database connections
4. Check external services (Auth0, Google AI)

### 3. Performance Degradation
1. Check Grafana dashboards
2. Check database slow query log
3. Check Redis cache hit rate
4. Check CPU/memory usage

## Troubleshooting

### Issue: Database Connection Failures

**Symptoms:**
- Application can't connect to database
- High number of connection errors

**Resolution:**
1. Check database is running: `docker ps | grep postgres`
2. Check connection string in .env
3. Check database logs: `docker logs postgres`
4. Restart database if needed: `docker-compose restart postgres`

### Issue: Auth0 Token Validation Failures

**Symptoms:**
- Users can't authenticate
- 401 errors on protected endpoints

**Resolution:**
1. Check Auth0 JWKS endpoint: `curl https://your-tenant.auth0.com/.well-known/jwks.json`
2. Check AUTH0_DOMAIN and AUTH0_AUDIENCE env vars
3. Verify JWT token with jwt.io
4. Check Auth0 dashboard for issues

## Contacts

- **On-Call Engineer:** +1-XXX-XXX-XXXX
- **DevOps Lead:** devops@contextai.com
- **Backend Team:** backend@contextai.com
- **Frontend Team:** frontend@contextai.com
```

---

## Issue 8.14: Setup Production Monitoring Dashboard

**Prioridad:** Alta  
**Dependencias:** 8.5, 8.6  
**Estimación:** 6 horas

### Descripción

Crear dashboard centralizado en Grafana con todas las métricas críticas, SLOs y health status visible en tiempo real.

### Acceptance Criteria

- [ ] Dashboard de Grafana con métricas clave
- [ ] Visualización de SLIs/SLOs
- [ ] Alertas visuales en dashboard
- [ ] Uptime tracking
- [ ] Request rate y latency
- [ ] Error rate tracking
- [ ] Business metrics dashboard
- [ ] Mobile-friendly dashboard

### Files to Create

```
config/grafana/main-dashboard.json            # Dashboard principal
config/grafana/business-metrics-dashboard.json # Métricas negocio
config/grafana/datasources.yml                # Datasources
docs/MONITORING_DASHBOARD.md                  # Documentación
```

### Technical Notes

```json
// main-dashboard.json (simplified)
{
  "dashboard": {
    "title": "Context.AI Production Overview",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "P95 Latency",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds)"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])"
          }
        ]
      },
      {
        "title": "Active Chat Sessions",
        "targets": [
          {
            "expr": "active_chat_sessions"
          }
        ]
      },
      {
        "title": "Documents Processed (24h)",
        "targets": [
          {
            "expr": "increase(documents_processed_total[24h])"
          }
        ]
      }
    ]
  }
}
```

---

## Resumen y Orden de Implementación

### Fase 1: Containerization (Paralelo)
1. Issue 8.1: Dockerize Backend Application
2. Issue 8.2: Dockerize Frontend Application

### Fase 2: CI/CD y Deployment (Secuencial)
3. Issue 8.3: Configure CI/CD Pipeline
4. Issue 8.9: Configure SSL/TLS and HTTPS
5. Issue 8.11: Configure Environment Management

### Fase 3: Observabilidad (Paralelo)
6. Issue 8.4: Implement Structured Logging
7. Issue 8.5: Implement APM
8. Issue 8.6: Implement Metrics with Prometheus
9. Issue 8.7: Implement Error Tracking with Sentry

### Fase 4: Reliability (Paralelo)
10. Issue 8.8: Configure Database Backups
11. Issue 8.10: Implement Alerting System
12. Issue 8.12: Implement Performance Optimization

### Fase 5: Documentation y Dashboards (Secuencial)
13. Issue 8.13: Create Operations Runbook
14. Issue 8.14: Setup Production Monitoring Dashboard

---

## Estimación Total

**Total de horas estimadas:** 83 horas  
**Total de sprints (2 semanas c/u):** ~2-3 sprints  
**Desarrolladores recomendados:** 2 (1 DevOps + 1 Full-Stack)

---

## Stack Tecnológico

### Infrastructure
- **Containerization:** Docker, Docker Compose
- **CI/CD:** GitHub Actions
- **Cloud Provider:** AWS/GCP/DigitalOcean (flexible)
- **Web Server:** Nginx

### Monitoring & Observability
- **APM:** New Relic o Datadog
- **Metrics:** Prometheus + Grafana
- **Logging:** Winston (structured JSON logs)
- **Error Tracking:** Sentry
- **Health Checks:** @nestjs/terminus

### Database & Caching
- **Primary DB:** PostgreSQL + pgvector
- **Cache:** Redis
- **Backups:** AWS S3 o similar

### Security
- **SSL/TLS:** Let's Encrypt
- **Secrets Management:** GitHub Secrets / HashiCorp Vault
- **Security Headers:** Configured in Nginx

---

## Dependencias Externas

### Backend Packages

```bash
# Monitoring
pnpm add winston
pnpm add newrelic @sentry/node @sentry/profiling-node
pnpm add prom-client
pnpm add @nestjs/terminus

# Caching
pnpm add @nestjs/cache-manager cache-manager cache-manager-redis-store redis

# Development
pnpm add -D @types/winston
```

### Infrastructure Tools

```bash
# Docker
docker --version
docker-compose --version

# SSL
certbot --version

# Monitoring
prometheus --version
grafana-cli --version
```

---

## Service Level Objectives (SLOs)

### Availability
- **Target:** 99.9% uptime (43.2 minutes downtime/month)
- **Measurement:** Uptime monitoring con health checks

### Performance
- **API Response Time:** P95 < 500ms, P99 < 1s
- **Chat Query:** P95 < 3s, P99 < 5s
- **Document Processing:** < 30s per document

### Error Rate
- **Target:** < 0.1% error rate
- **Critical Errors:** < 10 per day

### Business Metrics
- **Active Users:** Tracked daily
- **Documents Processed:** Tracked hourly
- **Chat Queries:** Tracked real-time

---

## Disaster Recovery Plan

### RTO (Recovery Time Objective)
- **Critical Services:** < 1 hour
- **Non-Critical Services:** < 4 hours

### RPO (Recovery Point Objective)
- **Database:** < 1 hour (hourly backups)
- **Application State:** < 24 hours

### Recovery Procedures

1. **Database Failure:**
   - Restore from latest backup
   - Run integrity checks
   - Resume service

2. **Application Failure:**
   - Rollback to previous stable version
   - Investigate root cause
   - Deploy fix

3. **Complete System Failure:**
   - Restore from backups
   - Rebuild infrastructure
   - Run smoke tests
   - Resume service

---

## Validación de Completitud

La Fase 8 se considera completa cuando:

- [ ] Todos los 14 issues están completados
- [ ] Aplicaciones dockerizadas y funcionando
- [ ] CI/CD pipeline operativo
- [ ] SSL/TLS configurado en producción
- [ ] Logging estructurado activo
- [ ] APM y métricas funcionando
- [ ] Error tracking configurado
- [ ] Backups automáticos funcionando
- [ ] Alerting system operativo
- [ ] Performance optimizada
- [ ] Runbook completo documentado
- [ ] Dashboard de monitoring activo
- [ ] Smoke tests pasando en producción
- [ ] SLOs siendo monitoreados

---

## Post-Deployment Checklist

```bash
# 1. Verify deployment
curl https://api.contextai.com/health

# 2. Check logs
docker-compose logs -f api

# 3. Run smoke tests
pnpm test:smoke

# 4. Check metrics
curl https://api.contextai.com/metrics

# 5. Verify monitoring
# - Check Grafana dashboards
# - Check Sentry for errors
# - Check APM for performance

# 6. Test critical paths
# - User login
# - Document upload
# - Chat query

# 7. Monitor for 30 minutes
# - Watch logs
# - Watch metrics
# - Watch error rates

# 8. Announce deployment
# - Notify team in Slack
# - Update status page
```

---

## Next Steps Post-Fase 8

Una vez completada la Fase 8:

1. **Production Launch:** Sistema en producción y operativo
2. **User Onboarding:** Comenzar onboarding de usuarios reales
3. **Performance Monitoring:** Monitor continuo de métricas
4. **Iteration:** Recopilar feedback y planear mejoras
5. **Scaling:** Planear estrategia de escalabilidad según demanda
6. **Post-MVP Features:** Implementar features del roadmap

---

## Documentation Links

- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Sentry](https://docs.sentry.io/)
- [Nginx](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)


