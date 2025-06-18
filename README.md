# Squads

A lightweight app for creating and browsing sports team squads, built as a monorepo:

- **Backend**: ✅ Python + FastAPI + PostgreSQL (completed)
- **Frontend**: 🚧 Flutter (Android, iOS, Web) - not yet implemented
- **Database**: PostgreSQL with Alembic migrations
- **Testing**: pytest for backend
- **Documentation**: .md files in `docs/`

---

## 📂 Repository structure

```
squads/
├── README.md             ← this file
├── .gitignore
├── docs/                 ← technical documentation (.md + config)
├── frontend/             ← Flutter app (not yet implemented)
│   ├── lib/              ← source code (screens/, widgets/, services/)
│   ├── test/             ← unit & widget tests
│   └── pubspec.yaml      ← Dart dependencies
├── backend/              ← FastAPI service + PostgreSQL (completed)
│   ├── app/
│   │   ├── main.py       ← creates FastAPI app, JWT, DB connection
│   │   ├── routes/       ← endpoints (squads, players, matches…)
│   │   ├── services/     ← business logic (CRUD, team drawing…)
│   │   ├── models/       ← SQLAlchemy models
│   │   ├── schemas/      ← Pydantic schemas
│   │   ├── entities/     ← data entities
│   │   └── utils/        ← auth, error handlers, CORS
│   ├── tests/            ← pytest (unit & integration)
│   ├── migrations/       ← Alembic database migrations
│   ├── requirements.txt
│   └── Dockerfile
├── docker-compose.yml    ← runs backend + PostgreSQL locally
└── .github/              ← CI/CD (GitHub Actions)
```

---

## 🚀 Quick start

### 1. Clone the repository

```bash
git clone https://github.com/Netherman2440/squads.git
cd squads
```

### 2. Common setup

- Install [Python 3.11+](https://www.python.org/downloads/)
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop) (for local backend + database)
- (Optional) [DBeaver](https://dbeaver.io/) or [pgAdmin](https://www.pgadmin.org/) for managing PostgreSQL

---

## 🖥️ Backend (FastAPI + PostgreSQL) - ✅ Completed

### Features implemented:
- ✅ FastAPI REST API with JWT authentication
- ✅ PostgreSQL database with SQLAlchemy ORM
- ✅ Alembic database migrations
- ✅ Squad management (CRUD operations)
- ✅ Player management within squads
- ✅ Match management and team drawing
- ✅ Comprehensive pytest test suite
- ✅ Docker support

### 1. Local development (recommended: Docker Compose)

1. **Start backend and database with Docker Compose**
   ```bash
   docker compose up --build
   ```
   - This will build the backend image and start both FastAPI and PostgreSQL containers.
   - FastAPI will be available at [http://localhost:8000](http://localhost:8000)
   - PostgreSQL will be available at `localhost:5432` (user: `postgres`, password: `password`, db: `mydb`)

2. **(Alternative) Run backend without Docker**
   - Install PostgreSQL locally and create a database.
   - Set environment variable `DATABASE_URL=postgresql://postgres:password@localhost:5432/mydb`
   - Install dependencies:
     ```bash
     cd backend
     pip install --upgrade pip
     pip install -r requirements.txt
     ```
   - Run database migrations:
     ```bash
     alembic upgrade head
     ```
   - Run the app:
     ```bash
     uvicorn app.main:app --reload
     ```

### 3. API Endpoints

The backend provides the following endpoints:

- **Squads**: `/squads/` - Create, read, update, delete squads
- **Players**: `/squads/{squad_id}/players/` - Manage players within squads
- **Matches**: `/squads/{squad_id}/matches/` - Create and manage matches
- **Team Drawing**: `/squads/{squad_id}/matches/draw` - Draw balanced teams

### 4. Authentication
- JWT-based authentication is implemented in the backend.
- On login, the backend returns a JWT token.
- The frontend must store the token securely and send it in the `Authorization: Bearer <token>` header for protected endpoints.

---

## 📱 Frontend (Flutter) - 🚧 Not yet implemented

The frontend is planned but not yet implemented. When ready, it will include:

- Flutter app for Android, iOS, and Web
- Integration with the FastAPI backend
- Squad and player management UI
- Match creation and team drawing interface

---

## 🧪 Tests

- **Backend** (completed):
  ```bash
  cd backend
  pytest
  ```
- **Frontend** (not yet implemented):
  ```bash
  cd frontend
  flutter test
  ```

---

## 📦 CI/CD

- **Backend**: `.github/workflows/python.yml` (ready for implementation)
- **Frontend**: `.github/workflows/flutter.yml` (ready for implementation)
- On every push to `main`:
  1. Lint & tests
  2. Build (Docker for backend, `flutter build web` for frontend)
  3. Automatic deploy (e.g. Google Cloud Run, Railway, Render, Firebase Hosting for frontend)

---

## 📖 Documentation

All architectural decisions and specifications are in the `docs/` folder:

- `docs/tech_stack.md`
- `docs/mvp.md`

---

## ☁️ Deployment (cloud)

- The backend (FastAPI) can be deployed to any cloud that supports Docker containers (e.g. Google Cloud Run, Railway, Render, Fly.io).
- The PostgreSQL database can be hosted as a managed service (recommended for production) or as a Docker container (for development).
- The frontend (Flutter Web) can be hosted on Netlify, Vercel, Firebase Hosting, or any static hosting.

---

## 🔗 Useful links

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [Flutter Docs](https://flutter.dev/docs) (for future frontend development)

---

> If you have questions or want to contribute – let me know!
