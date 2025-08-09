#!/bin/bash
# Python FastAPI Template

PROJECT_NAME="${1:-my-fastapi-app}"
echo "📦 Creating Python FastAPI project: $PROJECT_NAME"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Create requirements.txt
cat > requirements.txt << 'REQUIREMENTS'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.4.2
python-multipart==0.0.6
sqlalchemy==2.0.23
alembic==1.12.1
REQUIREMENTS

# Install dependencies
pip install -r requirements.txt

# Create main.py
cat > main.py << 'MAIN'
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="My FastAPI App")

class Item(BaseModel):
    name: str
    description: str = None

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}

@app.post("/items/")
def create_item(item: Item):
    return item
MAIN

# Initialize CCE
~/.cce-universal/scripts/init-project.sh .

echo "✅ Python FastAPI project created!"
echo "Run: cd $PROJECT_NAME && source venv/bin/activate && uvicorn main:app --reload"
