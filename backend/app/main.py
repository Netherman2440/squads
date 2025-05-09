import os
from typing import Union

import dotenv
from fastapi import FastAPI, File, UploadFile
from app.routes import auth
from app.services.database_service import DatabaseService
#.\.venv\Scripts\activate
#uvicorn app.main:app --reload  
app = FastAPI()

app.include_router(auth.router)
dotenv.load_dotenv()
database_service = DatabaseService(os.getenv("DATABASE_URL"))


create_table_query = """
    CREATE TABLE IF NOT EXISTS players (
        player_id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        age INTEGER,
        team VARCHAR(100)
    );
    """
database_service.insert_data(create_table_query)

@app.on_event("shutdown")
def shutdown_event():
    database_service.close()

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    # Odczytaj zawartość pliku
    contents = await file.read()
    # Tutaj możesz zapisać plik lub go przetworzyć
    return {"filename": file.filename, "content_type": file.content_type}




