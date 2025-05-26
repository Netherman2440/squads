import pytest

@pytest.fixture(scope="function", autouse=True)
def set_test_database_url(monkeypatch):
    # Podmiana zmiennej środowiskowej na czas testów
    monkeypatch.setenv("DATABASE_URL", "sqlite:///:memory:")
