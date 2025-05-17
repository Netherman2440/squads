from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routes.auth import router

app = FastAPI()
app.include_router(router)

client = TestClient(app)

def test_login():
    response = client.post("/login")
    assert response.status_code == 200
    assert response.json() == {"message": "Login successful"}
