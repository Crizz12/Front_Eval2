# Frontend — Innovatech Chile

Interfaz web de gestión de usuarios desarrollada en **Python + Flask**. Se comunica con el Backend API mediante peticiones HTTP REST y se despliega como contenedor Docker en AWS EC2.

---

## Arquitectura del sistema

```
Internet
    │
    ▼ (puerto 80)
┌─────────────────┐        red Docker interna         ┌──────────────────┐
│   EC2 pública   │ ──── http://proyecto_backend:3000 ──► EC2 / Backend   │
│   Frontend      │                                    │   (sin puerto    │
│   Flask :5000   │                                    │    expuesto)     │
└─────────────────┘                                    └──────────────────┘
```

- **Solo el Frontend es accesible desde Internet** (puerto 80).
- El Backend se comunica con el Frontend a través de la red interna Docker (`red_proyecto`), sin estar expuesto públicamente.

---

## Estructura del repositorio

```
Front_Eval2/
├── .github/
│   └── workflows/
│       └── deploy.yml      ← Pipeline CI/CD (GitHub Actions)
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── crear_usuario.html
│   ├── editar_usuario.html
│   ├── 404.html
│   └── 500.html
├── app.py                  ← Aplicación Flask principal
├── requirements.txt        ← Dependencias Python
├── Dockerfile              ← Imagen Docker multi-stage
├── docker-compose.yml      ← Levanta el Frontend de forma independiente
├── .env.example            ← Plantilla de variables de entorno
├── .gitignore
└── README.md
```

---

## Requisitos previos

| Herramienta | Versión mínima |
|---|---|
| Docker Desktop | 24.x |
| Docker Compose | v2.x |
| Python (sin Docker) | 3.8+ |

---

## Ejecución con Docker (recomendado)

### 1. Configurar variables de entorno

```bash
cp .env.example .env
```

Editar `.env`:

```env
BACKEND_URL=http://localhost:3000   # URL del backend (ajustar según entorno)
SECRET_KEY=una_clave_muy_segura
```

### 2. Levantar el contenedor

```bash
docker-compose up --build
```

El frontend quedará disponible en: `http://localhost`

### 3. Detener

```bash
docker-compose down
```

---

## Dockerfile — Multi-stage build

El `Dockerfile` usa **dos etapas** para reducir el tamaño final de la imagen:

| Etapa | Imagen base | Propósito |
|---|---|---|
| `builder` | `python:3.11-slim` | Instala dependencias con pip |
| producción | `python:3.11-slim` | Solo contiene el código y paquetes necesarios |

**Buenas prácticas aplicadas:**
- Usuario sin privilegios root (`appuser`) → seguridad de mínimo privilegio
- Copia de dependencias con `--no-cache-dir` → imagen más liviana
- Variables `PYTHONUNBUFFERED=1` → logs en tiempo real

---

## Variables de entorno

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `PORT` | Puerto del servidor Flask | `5000` |
| `DEBUG` | Modo debug | `False` |
| `BACKEND_URL` | URL del Backend API | `http://localhost:3000` |
| `SECRET_KEY` | Clave secreta para sesiones Flask | *(requerida)* |

> **Importante:** El archivo `.env` nunca debe subirse a GitHub. Está incluido en `.gitignore`.

---

## Pipeline CI/CD (GitHub Actions)

El archivo `.github/workflows/deploy.yml` automatiza el flujo completo:

```
push en rama 'deploy'
        │
        ▼
  [Job 1] Build & Push
  ┌─────────────────────────┐
  │ 1. Checkout del código  │
  │ 2. Login a Docker Hub   │
  │ 3. Build imagen Docker  │
  │ 4. Push → Docker Hub    │
  │    (tags: latest + SHA) │
  └─────────────────────────┘
        │
        ▼ (solo si Job 1 fue exitoso)
  [Job 2] Deploy en EC2
  ┌─────────────────────────┐
  │ 1. SSH a instancia EC2  │
  │ 2. docker pull latest   │
  │ 3. docker stop/rm old   │
  │ 4. docker run new       │
  └─────────────────────────┘
```

### Secrets requeridos en GitHub

Ir a: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Tu usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Token de acceso de Docker Hub |
| `EC2_HOST` | IP pública de la instancia EC2 |
| `EC2_USER` | Usuario SSH (`ubuntu` en Amazon Linux 2 es `ec2-user`) |
| `EC2_SSH_KEY` | Contenido completo del archivo `.pem` |
| `SECRET_KEY` | Clave secreta para sesiones Flask |

---

## Funcionalidades de la aplicación

| Ruta | Método | Descripción |
|---|---|---|
| `/` | GET | Lista todos los usuarios |
| `/crear` | GET / POST | Formulario para crear usuario |
| `/editar/<id>` | GET / POST | Formulario para editar usuario |
| `/eliminar/<id>` | POST | Elimina un usuario |

---

## Despliegue manual en EC2

Una vez que el contenedor del Backend esté corriendo en la misma instancia:

```bash
# Crear red compartida (si no existe)
docker network create red_proyecto

# Levantar el Frontend
docker run -d \
  --name proyecto_frontend \
  --network red_proyecto \
  --restart unless-stopped \
  -p 80:5000 \
  -e BACKEND_URL=http://proyecto_backend:3000 \
  -e SECRET_KEY="tu_clave_secreta" \
  tu_usuario/frontend-eval2:latest
```

Verificar que está corriendo:

```bash
docker ps
curl http://localhost
```
