# Dokumentacja architektury aplikacji

Poniższy dokument podsumowuje podjęte decyzje technologiczne i architektoniczne dla aplikacji do wybierania i zarządzania składami na mecz.

---

## 1. Tech Stack

* **Frontend:** Flutter

  * Framework: Flutter SDK
  * Obsługa platform: Android, iOS, Web (jedno repozytorium)
  * Początkowy stan: własne `ChangeNotifier` lub `InheritedWidget`
  * Docelowo: rozważenie **Provider** lub **Riverpod** dla lepszej testowalności i utrzymania

* **Backend:** Python + Flask

  * Framework: Flask microframework (znajomość oraz elastyczność)
  * Struktura: blueprinty w folderze `routes/`, logika w `services/`, modele w `models/`, schematy w `schemas/`

* **Baza danych:** Firebase Firestore (NoSQL)

  * Kolekcje: `players`, `teams`, `lineups`, `teamMembers`, `auditLogs`
  * Reguły bezpieczeństwa: Firestore Security Rules + transakcje dla spójnych update’ów

* **Auth & Cloud Code:**

  * Firebase Authentication (anonimowe & e-mail/hasło)
  * Google Cloud Run (konteneryzacja backendu) lub Cloud Functions jako ewentualna alternatywa serverless
  * IAM + Service Account w GCP do dostępu backendu do Firestore

* **CI/CD:** GitHub Actions

  * Kroki: lint → testy → budowa dockera → deploy na Cloud Run/Heroku

* **Monitoring & Logging:**

  * Logowanie błędów: Sentry lub Google Cloud Logging
  * Metryki i alerty: Prometheus + Grafana lub Google Cloud Monitoring

---

## 2. Architektura danych i modele

### 2.1. Schemat Firestore

* `teams/{teamId}`

  ```json
  {
    "name": "Drużyna A",
    "createdAt": <timestamp>
  }
  ```

* `players/{playerId}`

  ```json
  {
    "name": "Jan Kowalski",
    "number": 7,
    "stats": { /* ... */ },
    "linkedUserId": null  // później ID konta auth
  }
  ```

* `teamMembers/{autoId}` (lub subkolekcja pod `teams/{teamId}`)

  ```json
  {
    "userId": "UID_uzytkownika",
    "teamId": "teamId",
    "role": "admin"  // lub "member"
  }
  ```

* `lineups/{lineupId}`

  ```json
  {
    "teamId": "teamId",
    "date": "2025-05-10",
    "players": ["player_ABC123", "player_XYZ789"]
  }
  ```

* `auditLogs/{logId}` (opcjonalnie dla claim/unclaim)

  ```json
  {
    "action": "claim",
    "userId": "UID...",
    "playerId": "player_ABC123",
    "timestamp": <timestamp>,
    "result": "success"
  }
  ```

### 2.2. Rozdzielenie User ↔ Player

* **Player:** obiekt domenowy (statystyki, numer, referencja), bez poświadczeń
* **User:** konto Firebase Auth (anonimowe lub tradycyjne), zawiera mapę `roles` względem drużyn

Linkowanie:

* Inicjalnie `player.linkedUserId = null`
* Po claimie: aktualizujesz dokument `players/{playerId}.linkedUserId = auth.uid`

---

## 3. Autoryzacja i role

* **Role:** `guest`, `member`, `admin`

* **Dostęp:**

  * `guest`: GET list/drzewo składów i statystyk
  * `member`: GET + edycja własnego profilu
  * `admin`: pełne CRUD na drużynie, zawodnikach, składach

* **RBAC:** realizowane w middleware/dekoratorach Flask’a sprawdzających `teamMembers.role`

---

## 4. Struktura projektu (Flask)

```
/app
├─ models/
│   ├─ player.py
│   └─ team.py
├─ schemas/
│   ├─ player_schema.py
│   └─ team_schema.py
├─ services/
│   ├─ player_service.py
│   └─ team_service.py
├─ routes/
│   ├─ players.py    # blueprint `/players`
│   └─ teams.py      # blueprint `/teams`
├─ utils/
│   └─ auth.py       # JWT, role-checking
├─ main.py           # rejestracja blueprintów, uruchomienie app
└─ config.py         # ustawienia środowiskowe
```

---

## 5. API Endpoints (przykład)

* `GET /teams` → lista drużyn
* `POST /teams` → tworzy drużynę
* `GET /teams/{teamId}/lineups` → wszystkie składy drużyny
* `POST /teams/{teamId}/lineups` → dodaje nowy skład
* `POST /teams/{teamId}/players/{playerId}/claim` → claim profilu

---

## 6. Testy

* Katalog `tests/`:

  * `unit/`: testy jednostkowe (pytest)
  * `integration/`: testy endpointów z Firestore emulator
  * `e2e/`: scenariusze pełne (opcjonalnie)
* Frontend:

  * widget-testy Flutter + `integration_test` do flowy UX

---

## 7. Deployment

1. **Dockerfile** dla backendu:

   ```dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   COPY requirements.txt ./
   RUN pip install -r requirements.txt
   COPY . .
   CMD ["gunicorn", "main:app", "-b", "0.0.0.0:8080"]
   ```
2. **CI/CD:** GitHub Actions – testy, budowa obrazu, deploy na Cloud Run
3. **Firestore Auth:** Service Account z rolą „Datastore User”, klucz w `GOOGLE_APPLICATION_CREDENTIALS`

---

## 8. Monitoring & Logging

* **Logi:** integracja z Sentry / Cloud Logging
* **Metryki:** Prometheus + Grafana lub Cloud Monitoring
* **Alerty:** błędy 5xx, spadki wydajności, próby nadużyć claimu

---

## 9. Organizacja repozytoriów

Masz dwie główne strategie:

### A. Monorepo

Wszystkie komponenty (frontend, backend, dokumentacja) leżą w jednym repo:

```
/
├── docs/             # dokumentacja Markdown + config MkDocs/Docusaurus
├── frontend/         # kod Flutter
└── backend/          # kod Flask + skrypty deploy
```

**Zalety:**

* Wspólne wersjonowanie: zmiany w API i frontendzie zawsze zsynchronizowane.
* Wspólne CI/CD: jeden pipeline odpala testy frontu, testy backu, budowę docs.

**Wady:**

* Repo może rosnąć i stawać się ciężkie.
* Przy większym zespole ciężej zarządzać dostępami.

### B. Polyrepo (oddzielne repozytoria)

Oddzielny repo dla frontendu, backendu i dokumentacji:

```
- myapp-frontend (Flutter)
- myapp-backend  (Flask)
- myapp-docs     (Markdown + CI do publikacji)
```

**Zalety:**

* Każde repo jest lekkie, dedykowane, łatwiej zarządzać uprawnieniami.
* Niezależne cykle życia – front możesz deployować częściej niż backend.

**Wady:**

* Trudniej zsynchronizować zmiany między frontem a backiem.
* Więcej konfiguracji CI/CD (osobne pipeliny).

**Rekomendacja:** Monorepo na MVP/mały zespół; przejście do polyrepo przy wzroście projektu.

---

## 10. Middleware

**Middleware** to kod pośredniczący w przetwarzaniu żądań HTTP pomiędzy otrzymaniem requestu a obsługą w endpointzie (oraz analogicznie dla odpowiedzi).

### Typowe zastosowania:

1. **Autoryzacja i autentykacja**: dekodowanie JWT, wstawianie `current_user` do kontekstu.
2. **Obsługa błędów**: globalne łapanie wyjątków i standaryzacja odpowiedzi.
3. **CORS**: dodawanie nagłówków `Access-Control-Allow-*`.
4. **Logowanie requestów**: rejestrowanie metod, URL, czasu.
5. **Rate limiting**: ochrona przed nadmierną liczbą zapytań.
6. **Cache’owanie**: buforowanie wyników GET.

### Przykład w Flask:

```python
# utils/auth.py
from functools import wraps
from flask import request, jsonify, g
import jwt

def auth_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        except jwt.PyJWTError:
            return jsonify({'msg': 'Unauthorized'}), 401

        g.current_user = get_user_from_db(payload['uid'])
        return f(*args, **kwargs)
    return decorated

# main.py
from flask import Flask, jsonify
from utils.auth import auth_required

app = Flask(__name__)

@app.errorhandler(Exception)
def handle_all_errors(e):
    return jsonify({'error': str(e)}), 500

@app.route('/teams', methods=['GET'])
@auth_required
def list_teams():
    user = g.current_user
    return jsonify(teams)
```

**Dlaczego warto:**

* Unikasz duplikacji kodu w każdym endpointzie.
* Centralizujesz logikę bezpieczeństwa i obsługi błędów.

---

*Dokumentacja przeznaczona jako punkt wyjścia — można w nią wprowadzać kolejne detale i rozszerzenia.*
