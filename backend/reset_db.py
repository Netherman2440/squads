#!/usr/bin/env python3
"""
Skrypt do resetowania bazy danych - usuwa wszystkie tabele i tworzy je od nowa.
Użyj tego tylko w środowisku deweloperskim!
"""

import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Dodaj ścieżkę do app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import po dodaniu ścieżki
from app.database import Base, engine
from app.models import *  # Import wszystkich modeli

def get_database_url():
    """Pobierz URL bazy danych z zmiennych środowiskowych"""
    return os.getenv("DATABASE_URL", "sqlite:///./test.db")

def reset_database():
    """Usuwa wszystkie tabele i tworzy je od nowa"""
    
    print("🔄 Resetowanie bazy danych...")
    
    # Pobierz URL bazy danych
    database_url = get_database_url()
    print(f"📊 Baza danych: {database_url}")
    
    try:
        # Sprawdź czy baza istnieje i usuń wszystkie tabele
        with engine.connect() as conn:
            print("🗑️  Usuwanie wszystkich tabel...")
            
            # Wyłącz sprawdzanie kluczy obcych (dla PostgreSQL)
            if 'postgresql' in database_url:
                conn.execute(text("SET session_replication_role = replica;"))
            
            # Usuń wszystkie tabele
            Base.metadata.drop_all(engine)
            
            # Włącz z powrotem sprawdzanie kluczy obcych
            if 'postgresql' in database_url:
                conn.execute(text("SET session_replication_role = DEFAULT;"))
            
            conn.commit()
        
        print("✅ Wszystkie tabele zostały usunięte")
        
        # Utwórz wszystkie tabele od nowa
        print("🏗️  Tworzenie nowych tabel...")
        Base.metadata.create_all(engine)
        print("✅ Wszystkie tabele zostały utworzone")
        
        # Zasiej dane testowe (opcjonalnie)
        print("🌱 Dodawanie danych testowych...")
        try:
            from app.seed_db import seed_database
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            db = SessionLocal()
            
            try:
                seed_database()
                print("✅ Dane testowe zostały dodane")
            except Exception as e:
                print(f"⚠️  Błąd podczas dodawania danych testowych: {e}")
            finally:
                db.close()
        except ImportError:
            print("⚠️  Nie można zaimportować seed_database - pomijam dodawanie danych testowych")
        
        print("🎉 Reset bazy danych zakończony pomyślnie!")
        
    except Exception as e:
        print(f"❌ Błąd podczas resetowania bazy danych: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    # Potwierdzenie przed resetem
    print("⚠️  UWAGA: Ten skrypt usunie wszystkie dane z bazy!")
    print("Upewnij się, że masz kopię zapasową jeśli potrzebujesz.")
    
    response = input("Czy na pewno chcesz zresetować bazę danych? (tak/nie): ")
    
    if response.lower() in ['tak', 'yes', 'y', 't']:
        reset_database()
    else:
        print("❌ Reset anulowany.") 