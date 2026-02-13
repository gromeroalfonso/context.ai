# 🚀 Creación Automática de Issues - Fases 7 y 8

## 📋 Descripción

Este script crea automáticamente **todos los issues de las Fases 7 y 8** en GitHub siguiendo tu patrón establecido:
- **1 Issue Padre** por fase (con explicación completa de la fase)
- **Sub-issues** individuales para cada tarea

## ✅ Qué se creará

### Fase 7: Testing & Quality (17 issues)
- 1 Issue Padre: "Phase 7: Testing & Quality Assurance"
- 16 Sub-issues:
  - 7.1 a 7.5: Backend Testing
  - 7.6 a 7.9: Frontend Testing
  - 7.10 a 7.12: Performance & Quality
  - 7.13 a 7.16: Advanced Testing (a11y, security, visual, smoke)

### Fase 8: Deployment & Monitoring (15 issues)
- 1 Issue Padre: "Phase 8: Deployment & Monitoring"
- 14 Sub-issues:
  - 8.1 a 8.3: Infrastructure & CI/CD
  - 8.4 a 8.7: Observability
  - 8.8 a 8.10: Security & Alerting
  - 8.11 a 8.14: Operations

**TOTAL: 32 issues**

## 🔧 Prerequisitos

1. **GitHub CLI instalado** y autenticado:
   ```bash
   gh auth status
   ```
   
   Si no está autenticado:
   ```bash
   gh auth login
   ```

2. **Permisos de escritura** en el repositorio `gromeroalfonso/context-ai-api`

## 🚀 Ejecución

### Opción 1: Ejecutar directamente
```bash
cd "/Users/gabriela.romero/Master IA/Proyecto Final/Context.ai/Context.ia/scripts"
./create-phase-7-8-issues.sh
```

### Opción 2: Ejecutar desde cualquier lugar
```bash
bash "/Users/gabriela.romero/Master IA/Proyecto Final/Context.ai/Context.ia/scripts/create-phase-7-8-issues.sh"
```

## ⏱️ Tiempo estimado
- **Duración:** ~5-10 minutos (dependiendo de la conexión a internet)
- El script muestra progreso en tiempo real

## 📊 Qué verás durante la ejecución

```
🚀 Creando issues para Context.AI - Fases 7 y 8
================================================

🧪 FASE 7 - Testing & Quality
------------------------------
✅ Issue padre Fase 7 creado
✅ [Phase 7] 7.1: Optimize Backend Unit Tests
✅ [Phase 7] 7.2: Implement Backend Integration Tests
...
✅ Fase 7 completa: 1 issue padre + 16 sub-issues

🚀 FASE 8 - Deployment & Monitoring
------------------------------------
✅ Issue padre Fase 8 creado
✅ [Phase 8] 8.1: Dockerize Backend Application
...
✅ Fase 8 completa: 1 issue padre + 14 sub-issues

================================================
✅ CREACIÓN COMPLETA
================================================
📊 Resumen:
  - Fase 7: 1 padre + 16 sub-issues = 17 issues
  - Fase 8: 1 padre + 14 sub-issues = 15 issues
  - TOTAL: 32 issues creados
```

## 🎯 Siguiente paso: Organizar en GitHub Projects

Una vez creados los issues, puedes organizarlos en GitHub Projects:

1. **Ve a tu Project:** https://github.com/gromeroalfonso/context-ai-api/projects
2. **Agrega los issues** al proyecto:
   - Filtra por label: `phase-7-testing` y `phase-8-deployment`
   - Usa "Add items" para agregar todos los issues
3. **Organiza por Milestones:**
   - Milestone 7: Phase 7 - Testing & Quality
   - Milestone 8: Phase 8 - Deployment & Monitoring

## 🏷️ Labels que se crearán automáticamente

Los issues se etiquetarán con:

### Fase 7:
- `phase-7-testing`
- `priority-high` / `priority-medium` / `priority-low`
- `backend` / `frontend` / `devops`
- `epic` (solo para issue padre)

### Fase 8:
- `phase-8-deployment`
- `priority-high` / `priority-medium`
- `backend` / `frontend` / `devops` / `security` / `documentation`
- `epic` (solo para issue padre)

## 🔍 Verificación

Después de ejecutar, verifica en:
- **Issues:** https://github.com/gromeroalfonso/context-ai-api/issues
- **Filtrar por Fase 7:** `label:phase-7-testing`
- **Filtrar por Fase 8:** `label:phase-8-deployment`

## ⚠️ Troubleshooting

### Error: "gh: command not found"
```bash
# macOS
brew install gh

# Linux
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
&& sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
```

### Error: "unknown owner type" o "not authenticated"
```bash
gh auth login
# Seguir las instrucciones en pantalla
```

### Error: "permission denied"
```bash
chmod +x create-phase-7-8-issues.sh
```

## 📚 Referencias

- Documentación completa:
  - [Fase 7 Issues](../documentation/012-fase-7-testing-integration-issues.md)
  - [Fase 8 Issues](../documentation/013-fase-8-deployment-monitoring-issues.md)
- GitHub CLI Docs: https://cli.github.com/manual/

## ✅ Checklist post-ejecución

- [ ] Verificar que se crearon los 32 issues
- [ ] Asignar issues a ti mismo (si aplica)
- [ ] Agregar issues al GitHub Project
- [ ] Crear Milestones para Fase 7 y Fase 8
- [ ] Revisar y ajustar prioridades si es necesario
- [ ] Comenzar con el primer issue de Fase 7 🚀

