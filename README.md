# Context.ai 🧠✨
### El Orquestador de Cultura y Conocimiento Dinámico para Startups

---

## 📝 Descripción General
**Context.ai** es una solución de ingeniería diseñada para mitigar los problemas de fragmentación de información y la alta rotación en entornos de startups de alto crecimiento. A diferencia de las wikis tradicionales, Context.ai utiliza **IA Generativa y arquitecturas RAG (Retrieval-Augmented Generation)** para actuar como un "cerebro central" que facilita el onboarding autónomo y la retención del conocimiento táctico.

Este proyecto nace como el Trabajo de Fin de Máster del **Máster en Desarrollo con IA**, aplicando principios avanzados de **Ingeniería de Software**, **Arquitecturas Distribuidas** y **Desarrollo Potenciado por IA**.

### El Problema
* **Fragmentación**: Información dispersa en Slack, Confluence y documentos locales.
* **Onboarding costoso**: Los veteranos pierden tiempo valioso guiando a los nuevos.
* **Fuga de Conocimiento**: Cuando un empleado se va, su "know-how" desaparece con él.

---

## 🛠️ Stack Tecnológico
Para garantizar la escalabilidad, mantenibilidad y robustez, se ha seleccionado el siguiente stack:

* **Runtime & Lenguaje**: Node.js 22+ con TypeScript (tipado estricto).
* **Backend**: NestJS siguiendo patrones de **Arquitectura Limpia (Clean Architecture)** y **DDD**.
* **Frontend**: Next.js (App Router) optimizado para **Core Web Vitals**.
* **Orquestación de IA**: **Google Genkit** para flujos agénticos y Tool Calling.
* **Modelos (LLM)**: **Gemini 1.5 Pro** por su amplia ventana de contexto y multimodalidad.
* **Base de Datos**: Cloud SQL con la extensión **pgvector** para almacenamiento de embeddings vectoriales.
* **Observabilidad**: **Sentry** y **Genkit UI** para monitorización de latencia y alucinaciones.

---

## 🚀 Funcionalidades Principales
1.  **Aislamiento por Sectores**: Gestión de espacios de conocimiento por departamento (RRHH, Tech, Ventas) con control de acceso (RBAC).
2.  **Motor RAG Multimodal**: Ingesta y consulta de documentación (PDF, MD, Links) mediante búsqueda semántica avanzada.
3.  **Onboarding Playlists**: Creación de itinerarios de bienvenida automáticos.
4.  **Generación de Cápsulas Multimedia**: Uso de IA para crear videos y audios explicativos a partir de manuales técnicos.
5.  **Dashboard de Calidad (Feedback Loop)**: Análisis de sentimiento y puntuación de respuestas para identificar vacíos de información en la documentación.

---

🛠️ Stack Tecnológico:  
TODO
Backend (Core de Inteligencia)

Framework: NestJS con TypeScript (Node.js 22+).
Arquitectura: Clean Architecture y DDD (Domain-Driven Design).
Orquestación IA: Google Genkit para flujos agénticos y Tool Calling.
Base de Datos: PostgreSQL con pgvector para almacenamiento de embeddings.
Observabilidad: Sentry para monitorización de errores y rendimiento.

Frontend (Experiencia de Usuario)

Framework: Next.js (App Router).
Estilos: Tailwind CSS para una interfaz profesional y rápida.
Calidad: Optimización enfocada en Core Web Vitals.


---

## 📂 Estructura del Proyecto 

El código se organiza en dos aplicaciones principales para separar responsabilidades y facilitar el despliegue independiente. Sigue los principios de **Arquitectura Hexagonal** y **Domain-Driven Design (DDD)**:

TODO

---

🧪 Calidad, Seguridad y CI/CD

GitHub Actions: Automatización de tests y despliegue continuo.
Security by Design: Validación de entradas y sanitización para prevenir ataques OWASP.
Docker: Contenerización de servicios para entornos de desarrollo y producción.