# Squads

A lightweight app for creating and browsing sports team squads, built as a monorepo:

- **Frontend**: Flutter (Android, iOS, Web)
- **Backend**: Python + FastAPI
- **Database**: PostgreSQL
- **CI/CD**: GitHub Actions
- **Documentation**: .md files in `docs/`

---

## 📂 Repository structure

```
squads-monorepo/
├── README.md             ← this file
├── .gitignore
├── docs/                 ← technical documentation (.md + config)
├── frontend/             ← Flutter app
│   ├── lib/              ← source code (screens/, widgets/, services/)
│   ├── test/             ← unit & widget tests
│   └── pubspec.yaml      ← Dart dependencies
├── backend/              ← FastAPI service + PostgreSQL
│   ├── app/
│   │   ├── main.py       ← creates FastAPI app, JWT, DB connection
│   │   ├── routes/       ← endpoints (teams, players, matches…)
│   │   ├── services/     ← business logic (CRUD, rankings…)
│   │   └── utils/        ← auth, error handlers, CORS
│   ├── tests/            ← pytest (unit & integration)
│   ├── requirements.txt
│   ├── Dockerfile
│   └── alembic/          ← DB migrations (optional, if using Alembic)
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

- Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Install [Python 3.11+](https://www.python.org/downloads/)
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop) (for local backend + database)
- (Optional) [DBeaver](https://dbeaver.io/) or [pgAdmin](https://www.pgadmin.org/) for managing PostgreSQL

---

## 🖥️ Backend (FastAPI + PostgreSQL)

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
   - Run the app:
     ```bash
     uvicorn app.main:app --reload
     ```

### 3. Authentication
- JWT-based authentication is implemented in the backend.
- On login, the backend returns a JWT token.
- The frontend must store the token securely and send it in the `Authorization: Bearer <token>` header for protected endpoints.

---

## 📱 Frontend (Flutter)

1. **Go to the directory and get dependencies**
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Run the app**
   - **Android/iOS** (device or emulator):
     ```bash
     flutter run
     ```
   - **Web**:
     ```bash
     flutter run -d chrome
     ```

3. **Set API address**
   By default, the frontend connects to `http://localhost:8000`.
   You can override this:
   ```bash
   flutter run --dart-define=API_URL=https://your-backend-url.com
   ```

---

## 🧪 Tests

- **Backend**:
  ```bash
  cd backend
  pytest
  ```
- **Frontend**:
  ```bash
  cd frontend
  flutter test
  ```

---

## 📦 CI/CD

- **Backend**: `.github/workflows/python.yml`
- **Frontend**: `.github/workflows/flutter.yml`
- On every push to `main`:
  1. Lint & tests
  2. Build (Docker for backend, `flutter build web` for frontend)
  3. Automatic deploy (e.g. Google Cloud Run, Railway, Render, Firebase Hosting for frontend)

---

## 📖 Documentation

All architectural decisions and specifications are in the `docs/` folder:

- `docs/tech-stack.md`
- `docs/scope-mvp.md`

You can build and preview it locally using MkDocs or Docusaurus.

---

## ☁️ Deployment (cloud)

- The backend (FastAPI) can be deployed to any cloud that supports Docker containers (e.g. Google Cloud Run, Railway, Render, Fly.io).
- The PostgreSQL database can be hosted as a managed service (recommended for production) or as a Docker container (for development).
- The frontend (Flutter Web) can be hosted on Netlify, Vercel, Firebase Hosting, or any static hosting.

---

## 🔗 Useful links

- [Flutter Docs](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/actions)

---

> If you have questions or want to contribute – let me know!
