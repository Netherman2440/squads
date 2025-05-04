# Zakres MVP

Dokument definiuje minimalny zakres funkcjonalny (MVP) aplikacji do wybierania i zarządzania składami na mecz.

---

## 1. Baza danych (Firebase Firestore SQL)

* **Modele (kolekcje):**

  * `teams` — drużyny
  * `players` — zawodnicy
  * `matches` — mecze
  * `users` — konta użytkowników (na razie tylko jedno konto: Ty)

    * Goście („guest”) nie zakładają kont — mają tylko dostęp do odczytu danych.

* **Relacje:**

  * `teams/{teamId}` przechowuje dane drużyny.
  * `players/{playerId}` z polem `teamId` wskazującym drużynę.
  * `matches/{matchId}` zawiera datę, uczestników (`playerIds`) i wynik.
  * `users/{userId}` z mapą ról względem `teamId` (na razie `{ yourId: "admin" }`).

---

## 2. Backend (Flask)

### 2.0. Inicjalizacja projektu

1. **Środowisko Python**

   * Zainstaluj Pythona w wersji >=3.10.
   * W katalogu `backend/` utwórz wirtualne środowisko:

     ```bash
     python -m venv .venv
     source .venv/bin/activate   # Linux/Mac
     .venv\Scripts\activate    # Windows
     ```
2. **Struktura katalogów**

   ```
   backend/
   ├── app/
   │   ├── models/          # definicje ORM lub Firestore wrappers
   │   ├── schemas/         # Pydantic/Marshmallow
   │   ├── services/        # logika biznesowa
   │   ├── routes/          # blueprinty / CCTV
   │   ├── utils/           # middleware, auth, helpery
   │   └── main.py          # punkt wejścia aplikacji
   ├── requirements.txt     # zależności
   ├── config.py            # ustawienia środowiskowe
   └── .venv/               # wirtualne środowisko
   ```
3. **Dependencies**

   * W `requirements.txt` umieść:

     ```txt
     Flask
     google-cloud-firestore
     Flask-JWT-Extended
     gunicorn
     pytest
     ```
   * Zainstaluj je:

     ```bash
     pip install -r requirements.txt
     ```

### 2.1. Konfiguracja połączenia z Firestore

* Utwórz Service Account w Google Cloud z rolą `Cloud Datastore User`.
* Pobierz JSON z kluczami i ustaw zmienną środowiskową:

  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
  ```
* W `config.py` zarządzaj ścieżką:

  ```python
  import os
  FIRESTORE_CREDENTIALS = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
  ```

### 2.2. Główny punkt wejścia (`main.py`)

```python
from flask import Flask
from routes.teams import teams_bp
from routes.players import players_bp
from routes.matches import matches_bp
from utils.auth import init_jwt, auth_error_handler

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'YOUR_SECRET'

# inicjalizacja JWT
init_jwt(app)
# globalny handler błędów
app.register_error_handler(Exception, auth_error_handler)

# rejestracja blueprintów
app.register_blueprint(teams_bp, url_prefix='/teams')
app.register_blueprint(players_bp, url_prefix='/players')
app.register_blueprint(matches_bp, url_prefix='/matches')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

### 2.3. Autoryzacja

* **Flask-JWT-Extended**:

  * `POST /users/login` zwraca token JWT.
  * Dekorator `@jwt_required()` zabezpiecza endpointy.
  * W middleware sprawdzasz `get_jwt_identity()` i odczytujesz w `UserService` role.

### 2.4. REST API

* **Endpointy:**

  * `GET /teams`, `POST /teams`, `PUT /teams/{id}`, `DELETE /teams/{id}`
  * `GET /players`, `POST /players`, `PUT /players/{id}`, `DELETE /players/{id}`
  * `GET /matches`, `POST /matches`, `PUT /matches/{id}`, `DELETE /matches/{id}`
  * `POST /users/login` → payload `{email, password}` → zwraca `{access_token}`

### 2.5. Testy

* **Unit tests** (pytest) dla usług w `services/`:

  * `tests/unit/test_team_service.py`, `test_player_service.py`, etc.
* **Integration tests**:

  * Użyj Firestore emulatora, fixture `firebase_emulator` w pytest.
  * Testy endpointów HTTP: `client = app.test_client()` + CRUD flows.

### 2.6. Logika biznesowa

* Operacje w `services/`:

  * `TeamService.create_team()`, `TeamService.update_team()`, etc.
  * `PlayerService.add_player_to_team()`, `PlayerService.update_stats()`.
  * `MatchService.create_match()`, `MatchService.record_result()`, `MatchService.update_rankings()`.
  * `UserService.authenticate()`, `UserService.get_user_roles()`.

---

## 3. Frontend (Flutter)

(Flutter)

* **Ekrany:**

  * **Lista drużyn**: widok wszystkich `teams`
  * **Szczegóły drużyny**: lista `players`, dostęp do `matches`
  * **Formularz meczu**: wybór uczestników, wprowadzenie wyniku
  * **Panel admina** (tylko po zalogowaniu): CRUD dla wszystkich zasobów

* **Logika**:

  * Wywoływanie REST API dla CRUD
  * Parsowanie JSON → modele Dart (`Team`, `Player`, `Match`)
  * Wyświetlanie rankingów i statystyk

---

*Zakres MVP obejmuje bazową funkcjonalność: przechowywanie i odczyt danych, podstawowe zarządzanie składami oraz mechanizm autoryzacji dla administracji.*
