# Especificación de Requisitos: Contxt.ai
## El Orquestador de Cultura y Conocimiento Dinámico

### 1. Propósito y Contexto de Negocio
Contxt.ai nace para resolver la fragmentación de información y la alta rotación en entornos de startups. El proyecto se centra en:
* **Centralización**: Unificar el conocimiento disperso en múltiples herramientas.
* **Onboarding Autónomo**: Reducir la dependencia de mentores mediante tutores personalizados con IA.
* **Retención de Conocimiento**: Asegurar que el "know-how" permanezca en la empresa a pesar de la rotación.

---

### 2. Requisitos Funcionales (RF)
Definen las acciones específicas que el sistema debe realizar:

* **RF-1: Gestión de Espacios (Sectores)**: El sistema permitirá crear áreas aisladas de conocimiento (RRHH, Tech, Ventas).
* **RF-2: Ingesta Multimodal (RAG)**: Capacidad de indexar y recuperar información de archivos PDF, Markdown y enlaces externos.
* **RF-3: Generación de Cápsulas Multimedia**: Creación automática de guiones y audios explicativos (Text-to-Speech) para nuevos empleados.
* **RF-4: Consultas Especializadas**: Chatbot que utiliza agentes inteligentes para responder dudas basadas únicamente en el contexto del sector.
* **RF-5: Dashboard de Análisis de Sentimiento**: Herramienta para que RRHH evalúe la claridad de la documentación según el feedback del usuario.

---

### 3. Requisitos No Funcionales (RNF)
Definen las propiedades y restricciones del sistema:

* **Arquitectura**: Implementación de **Clean Architecture** y **Arquitectura Hexagonal** para asegurar desacoplamiento y testabilidad.
* **Rendimiento**: Optimización de carga y respuesta siguiendo métricas de **Core Web Vitals**.
* **Observabilidad**: Monitorización de errores, latencia y rendimiento de LLMs mediante **Sentry** y **Genkit UI**.
* **Escalabilidad**: Diseño preparado para despliegue en la nube mediante contenedores y pipelines de **CI/CD**.

---

### 4. Restricciones Técnicas
Limitaciones tecnológicas obligatorias para el desarrollo:

| Componente | Tecnología Seleccionada | Justificación Técnica |
| :--- | :--- | :--- |
| **Runtime** | Node.js 22+ (TypeScript) | Soporte para asincronía y tipado robusto. |
| **Backend** | NestJS | Facilita el uso de DDD y SOLID. |
| **Frontend** | Next.js | Optimización de UX y SSR. |
| **Orquestación IA** | Google Genkit | Flujos agénticos y Tool Calling avanzado. |
| **Modelos (LLM)** | Gemini 2.5 Flash | Amplia ventana de contexto para RAG. |
| **Base de Datos** | Cloud SQL & Pinecone (vectorial) | Almacenamiento relacional y vectorial. |

---

### 5. Requisitos de Seguridad y Datos
* **Seguridad por Diseño**: Implementación de **Security by Design** y protección contra el **OWASP Top 10 2025**.
* **Gestión de Identidad**: Control de acceso basado en roles (RBAC) para proteger información sensible por sector.
* **Privacidad**: Cumplimiento de buenas prácticas en el manejo de datos para evitar fugas en modelos de IA.
* **Ciclo de Vida del Dato**: Almacenamiento de embeddings vectoriales y trazabilidad de evaluaciones de IA.

---

### 6. Requisitos de Negocio (Business Requirements)
Definen los objetivos estratégicos de la startup para este proyecto:

* **RN-1: Reducción del Tiempo de Onboarding**: Automatizar la entrega de conocimiento para que un nuevo integrante sea operativo en un 30% menos de tiempo sin intervención humana constante.
* **RN-2: Centralización del Capital Intelectual**: Evitar la fuga de conocimiento provocada por la alta tasa de rotación, asegurando que la información crítica resida en la plataforma y no solo en las personas.
* **RN-3: Optimización de Roles Mixtos**: Facilitar que empleados con múltiples funciones accedan rápidamente a guías de procesos de áreas que no son su especialidad principal.
* **RN-4: Retorno de Inversión en Formación**: Demostrar la aplicabilidad real de la IA para mejorar los procesos internos.

---

### 7. Requisitos de Usuario (User Requirements)

#### A. Perfil RRHH / Gestión (Administrador de Contenido)
* **RU-1: Creación de Bases de Conocimiento (RAG)**: El usuario debe poder crear "sectores" aislados subiendo documentación específica para generar una base de conocimiento especializada.
* **RU-2: Automatización de Contenido Multimedia**: Posibilidad de generar guiones y cápsulas de video/audio mediante IA a partir de los documentos subidos para hacer el aprendizaje más ameno.
* **RU-3: Gestión de Permisos por Rol**: Definir qué usuarios o departamentos tienen acceso a qué bases de conocimiento (ej. Ventas no accede a RRHH).
* **RU-4: Supervisión de Calidad (Feedback Loop)**: Visualizar un dashboard que resuma si la información es útil para los empleados mediante el análisis de sentimiento de sus consultas.

#### B. Perfil Nuevo Integrante / Empleado (Consumidor de Contenido)
* **RU-5: Consulta en Lenguaje Natural**: El usuario debe poder preguntar cualquier duda a la IA y recibir una respuesta basada exclusivamente en la documentación oficial de la empresa.
* **RU-6: Onboarding Autoguiado**: Visualizar un itinerario de bienvenida con los videos y documentos generados específicamente para su puesto.
* **RU-7: Sistema de Calificación**: El usuario podrá puntuar la utilidad de las respuestas recibidas para ayudar a identificar documentación que necesita ser actualizada o mejorada.