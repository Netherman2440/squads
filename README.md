# Squads

Lekka aplikacja do tworzenia i przeglądania składów drużyn sportowych, zbudowana jako monorepo:

- **Frontend**: Flutter (Android, iOS, Web)  
- **Backend**: Python + Flask  
- **Baza danych**: Google Firestore  
- **CI/CD**: GitHub Actions  
- **Dokumentacja**: MkDocs/Docusaurus w folderze `docs/`

---

## 📂 Struktura repozytorium

```
squads-monorepo/
├── README.md             ← ten plik
├── .gitignore
├── docs/                 ← dokumentacja techniczna (.md + config)
├── frontend/             ← aplikacja Flutter
│   ├── lib/              ← kod źródłowy (screens/, widgets/, services/)
│   ├── test/             ← testy unit & widget
│   └── pubspec.yaml      ← zależności Dart
├── backend/              ← serwis Flask + Firestore
│   ├── app/
│   │   ├── main.py       ← tworzy Flask-app, JWT, Firestore
│   │   ├── routes/       ← endpointy (teams, players, matches…)
│   │   ├── services/     ← logika biznesowa (CRUD, rankingi…)
│   │   └── utils/        ← auth, error handlers, CORS
│   ├── tests/            ← pytest (unit & integracja)
│   ├── requirements.txt  
│   └── Dockerfile
└── .github/              ← CI/CD (GitHub Actions)
```

---

## 🚀 Szybki start

### 1. Klonowanie repozytorium

```bash
git clone https://github.com/TwojeRepo/squads-monorepo.git
cd squads-monorepo
```

### 2. Ustawienia wspólne

- Zainstaluj [Flutter SDK](https://flutter.dev/docs/get-started/install)  
- Zainstaluj [Python 3.11+](https://www.python.org/downloads/)  
- (Opcjonalnie) [Firebase CLI](https://firebase.google.com/docs/cli) do emulatorów  

---

## 🖥️ Backend (Flask + Firestore)

1. **Utwórz i aktywuj wirtualne środowisko**  
   ```bash
   cd backend
   python -m venv .venv
   # Windows PowerShell:
   .venv\Scripts\Activate.ps1
   # Bash (Linux/macOS):
   source .venv/bin/activate
   ```

2. **Zainstaluj zależności**  
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. **Poświadczenia do Firestore**  
   - Pobierz `service-account.json` z Google Cloud Console  
   - Ustaw zmienną środowiskową:
     ```bash
     # Windows PowerShell
     $Env:GOOGLE_APPLICATION_CREDENTIALS="C:\ścieżka\do\service-account.json"

     # Linux/macOS
     export GOOGLE_APPLICATION_CREDENTIALS="/full/path/service-account.json"
     ```

4. **(Opcjonalnie) Emulator Firestore**  
   ```bash
   firebase emulators:start --only firestore
   # w nowym oknie terminala:
   export USE_FIRESTORE_EMULATOR=1
   ```

5. **Uruchom serwis**  
   ```bash
   flask run --host=0.0.0.0 --port=5000
   # będzie dostępny pod http://localhost:5000
   ```

---

## 📱 Frontend (Flutter)

1. **Przejdź do katalogu i pobierz zależności**  
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Uruchom aplikację**  
   - **Android/iOS** (urządzenie lub emulator):
     ```bash
     flutter run
     ```
   - **Web**:
     ```bash
     flutter run -d chrome
     ```

3. **Wskaż adres API**  
   Domyślnie frontend łączy się z `http://localhost:5000`.  
   Możesz nadpisać to:
   ```bash
   flutter run --dart-define=API_URL=https://squads-backend-abcdefg.a.run.app
   ```

---

## 🧪 Testy

- **Backend**:  
  ```bash
  cd backend
  source .venv/bin/activate
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
- Po każdym pushu do `main`:
  1. Lint & testy  
  2. Build (Docker dla backendu, `flutter build web` dla frontu)  
  3. Automatyczny deploy (np. Google Cloud Run, Firebase Hosting)

---

## 📖 Dokumentacja

Wszystkie decyzje architektoniczne i specyfikacje znajdziesz w folderze `docs/`:

- `docs/tech-stack.md`  
- `docs/scope-mvp.md`  

Możesz zbudować i podejrzeć ją lokalnie za pomocą MkDocs albo Docusaurus.

---

## 🔗 Przydatne linki

- [Flutter Docs](https://flutter.dev/docs)  
- [Flask Documentation](https://flask.palletsprojects.com/)  
- [Firestore Python Client](https://googleapis.dev/python/firestore/latest/index.html)  
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)  
- [GitHub Actions](https://docs.github.com/actions)

---

> Jeśli masz pytania lub chcesz rozszerzyć projekt – daj znać!
