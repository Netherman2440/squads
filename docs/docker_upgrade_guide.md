# Instrukcje Upgradowania Kontenera Backend

## Przegląd
Ten dokument zawiera instrukcje krok po krok do upgradowania kontenera backendowego w Dockerze.

## Wymagania wstępne
- Docker i Docker Compose zainstalowane
- Dostęp do terminala/PowerShell
- Backup bazy danych (jeśli potrzebny)

## Rodzaje Upgradów

### 1. Upgrade tylko kodu aplikacji (bez zmian w requirements.txt)

Jeśli zmieniłeś tylko kod Python bez dodawania nowych dependencji:

```bash
# 1. Zatrzymaj kontener
docker-compose down

# 2. Restart kontenera (volume mount załaduje nowy kod automatycznie)
docker-compose up -d backend

# 3. Sprawdź logi
docker-compose logs -f backend
```

### 2. Upgrade z nowymi dependencjami Python

Gdy dodałeś nowe biblioteki do `requirements.txt`:

```bash
# 1. Zatrzymaj kontener
docker-compose down

# 2. Rebuild obrazu z nowymi dependencjami
docker-compose build backend --no-cache

# 3. Uruchom kontener z nowym obrazem
docker-compose up -d backend

# 4. Sprawdź czy dependencje zostały zainstalowane
docker-compose exec backend pip list

# 5. Sprawdź logi
docker-compose logs -f backend
```

### 3. Upgrade z migracjami bazy danych

Gdy masz nowe migracje Alembic:

```bash
# 1. Zatrzymaj kontener
docker-compose down

# 2. (Opcjonalnie) Backup bazy danych
# docker-compose exec db pg_dump -U username dbname > backup.sql

# 3. Rebuild obrazu jeśli potrzeba
docker-compose build backend --no-cache

# 4. Uruchom kontener
docker-compose up -d backend

# 5. Uruchom migracje
docker-compose exec backend alembic upgrade head

# 6. Sprawdź status migracji
docker-compose exec backend alembic current

# 7. Sprawdź logi
docker-compose logs -f backend
```

### 4. Pełny upgrade systemu

Kompleksowy upgrade wszystkich komponentów:

```bash
# 1. Zatrzymaj wszystkie serwisy
docker-compose down

# 2. Usuń stare obrazy (opcjonalnie)
docker image prune -a

# 3. Rebuild wszystkich serwisów
docker-compose build --no-cache

# 4. Uruchom wszystkie serwisy
docker-compose up -d

# 5. Uruchom migracje jeśli potrzeba
docker-compose exec backend alembic upgrade head

# 6. Sprawdź status wszystkich kontenerów
docker-compose ps

# 7. Sprawdź logi
docker-compose logs -f
```

## Często używane komendy

### Monitoring i diagnostyka
```bash
# Sprawdź status kontenerów
docker-compose ps

# Sprawdź logi backendu
docker-compose logs -f backend

# Sprawdź logi z ostatnich 100 linii
docker-compose logs --tail=100 backend

# Sprawdź zużycie zasobów
docker stats

# Wejście do kontenera (debugging)
docker-compose exec backend bash
```

### Zarządzanie obrazami
```bash
# Lista obrazów
docker images

# Usuń nieużywane obrazy
docker image prune

# Usuń konkretny obraz
docker rmi squads-backend

# Rebuild bez cache
docker-compose build backend --no-cache
```

### Zarządzanie bazą danych
```bash
# Sprawdź aktualną wersję migracji
docker-compose exec backend alembic current

# Historia migracji
docker-compose exec backend alembic history

# Uruchom konkretną migrację
docker-compose exec backend alembic upgrade <revision>

# Cofnij migrację
docker-compose exec backend alembic downgrade <revision>
```

## Procedura bezpiecznego upgradu

### Krok 1: Przygotowanie
```bash
# Sprawdź aktualny status
docker-compose ps
docker-compose logs --tail=20 backend

# Backup bazy danych (jeśli potrzeba)
# Zapisz aktualną wersję kodu
```

### Krok 2: Zatrzymanie serwisów
```bash
docker-compose down
```

### Krok 3: Upgrade
```bash
# Wybierz odpowiednią metodę z powyższych sekcji
# w zależności od typu zmian
```

### Krok 4: Weryfikacja
```bash
# Sprawdź czy backend odpowiada
curl http://localhost:20757/docs

# Sprawdź logi pod kątem błędów
docker-compose logs backend | grep -i error

# Test podstawowej funkcjonalności API
curl http://localhost:20757/health
```

### Krok 5: Rollback (jeśli potrzeba)
```bash
# Jeśli coś poszło nie tak:
docker-compose down

# Przywróć poprzednią wersję kodu
git checkout <previous-commit>

# Rebuild i restart
docker-compose build backend --no-cache
docker-compose up -d backend

# Jeśli potrzeba, cofnij migracje
docker-compose exec backend alembic downgrade <previous-revision>
```

## Troubleshooting

### Typowe problemy i rozwiązania

**Kontener nie startuje:**
```bash
# Sprawdź logi
docker-compose logs backend

# Sprawdź konfigurację
docker-compose config

# Rebuild bez cache
docker-compose build backend --no-cache
```

**Błędy dependencji:**
```bash
# Usuń wszystkie obrazy i rebuild
docker-compose down
docker system prune -a
docker-compose build --no-cache
```

**Problemy z bazą danych:**
```bash
# Sprawdź status migracji
docker-compose exec backend alembic current

# Reset bazy danych (UWAGA: usuwa dane!)
docker-compose exec backend python reset_db.py
```

**Port już używany:**
```bash
# Sprawdź co używa portu 20757
netstat -tulpn | grep 20757

# Zmień port w docker-compose.yml lub zatrzymaj konfliktujący proces
```

## Zmienne środowiskowe

Pamiętaj o ustawieniu wymaganych zmiennych przed startem:

```bash
# Utwórz plik .env w root projektu
DATABASE_URL=your_database_url
ENVIRONMENT=production
```

## Monitorowanie po upgrade

Po każdym upgrade monitoruj:
- Logi aplikacji przez co najmniej 10 minut
- Zużycie CPU i pamięci
- Czas odpowiedzi API
- Połączenia z bazą danych

```bash
# Ciągłe monitorowanie logów
docker-compose logs -f backend

# Monitoring zasobów
docker stats squads-backend-1
``` 