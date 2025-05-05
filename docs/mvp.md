# MVP Scope

This document defines the minimal functional scope (MVP) of the application for creating and managing sports team squads.

---

## 1. Database (PostgreSQL)

* **Models (tables):**
  * `teams` — teams
  * `players` — players
  * `matches` — matches
  * `users` — user accounts (initially only one admin account: you)
    * Guests do not create accounts — they have read-only access.

* **Relations:**
  * `teams.id` — primary key for teams.
  * `players.team_id` — foreign key referencing the team.
  * `matches.id` — contains date, participants (`player_ids`), and result.
  * `users.id` — user account, with a role field (e.g., `{ your_id: "admin" }`).

---

## 2. Backend (FastAPI)

### 2.0. Project initialization

1. **Python environment**
   * Install Python >=3.11.
   * In the `backend/` directory, create a virtual environment:
     ```bash
     python -m venv .venv
     source .venv/bin/activate   # Linux/Mac
     .venv\Scripts\activate      # Windows
     ```

2. **Directory structure**
   ```
   backend/
   ├── app/
   │   ├── models/          # ORM definitions (SQLAlchemy)
   │   ├── schemas/         # Pydantic schemas
   │   ├── services/        # business logic
   │   ├── routes/          # API endpoints
   │   ├── utils/           # auth, helpers, error handlers
   │   └── main.py          # app entry point
   ├── requirements.txt     # dependencies
   ├── config.py            # environment settings
   └── .venv/               # virtual environment
   ```

3. **Dependencies**
   * In `requirements.txt`:
     ```txt
     fastapi
     uvicorn
     sqlalchemy
     psycopg2-binary
     pydantic
     python-jose
     passlib[bcrypt]
     pytest
     ```
   * Install them:
     ```bash
     pip install -r requirements.txt
     ```

### 2.1. Database connection (PostgreSQL)

* Configure the connection string in `config.py`:
  ```python
  import os
  DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost:5432/mydb')
  ```

* Use SQLAlchemy for ORM and migrations (optionally Alembic).

### 2.2. Main entry point (`main.py`)

```python
from fastapi import FastAPI
from app.routes.teams import router as teams_router
from app.routes.players import router as players_router
from app.routes.matches import router as matches_router
from app.routes.auth import router as auth_router

app = FastAPI()

app.include_router(teams_router, prefix="/teams")
app.include_router(players_router, prefix="/players")
app.include_router(matches_router, prefix="/matches")
app.include_router(auth_router, prefix="/auth")
```

### 2.3. Authorization

* **JWT-based authentication**:
  * `POST /auth/login` returns a JWT token.
  * Use `Depends(get_current_user)` to protect endpoints.
  * The backend verifies the JWT and checks user roles.

### 2.4. REST API

* **Endpoints:**
  * `GET /teams`, `POST /teams`, `PUT /teams/{id}`, `DELETE /teams/{id}`
  * `GET /players`, `POST /players`, `PUT /players/{id}`, `DELETE /players/{id}`
  * `GET /matches`, `POST /matches`, `PUT /matches/{id}`, `DELETE /matches/{id}`
  * `POST /auth/login` → payload `{email, password}` → returns `{access_token}`

### 2.5. Tests

* **Unit tests** (pytest) for services in `services/`:
  * `tests/unit/test_team_service.py`, `test_player_service.py`, etc.
* **Integration tests**:
  * Use a test PostgreSQL database (can be a separate Docker container).
  * HTTP endpoint tests: `client = TestClient(app)` + CRUD flows.

### 2.6. Business logic

* Operations in `services/`:
  * `TeamService.create_team()`, `TeamService.update_team()`, etc.
  * `PlayerService.add_player_to_team()`, `PlayerService.update_stats()`.
  * `MatchService.create_match()`, `MatchService.record_result()`, `MatchService.update_rankings()`.
  * `UserService.authenticate()`, `UserService.get_user_roles()`.

---

## 3. Frontend (Flutter)

* **Screens:**
  * **Teams list**: view all `teams`
  * **Team details**: list of `players`, access to `matches`
  * **Match form**: select participants, enter result
  * **Admin panel** (only after login): CRUD for all resources

* **Logic:**
  * Call REST API for CRUD operations
  * Parse JSON → Dart models (`Team`, `Player`, `Match`)
  * Display rankings and statistics

---

*MVP scope covers basic functionality: data storage and retrieval, basic squad management, and an authorization mechanism for administration.*
