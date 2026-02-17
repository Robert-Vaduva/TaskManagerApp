# 🚀 Full-Stack FastAPI & Flutter Template
A modern, modular, and secure boilerplate for commercial applications, built with a layered architecture.

## 🛠 Tech Stack
- **Backend:** FastAPI (Python 3.14+), SQLAlchemy, PostgreSQL, JWT, SHA-256 Hashing.
- **Frontend:** Flutter SDK.
- **Infrastructure:** Docker & Docker Compose.

## 📋 Quick Start

### 1. Clone and Environment Setup
git clone <url-ul-tau>
cd MyFirstApp
cp backend/.env.example backend/.env
# Generate unique ssl secret key
openssl rand -hex 32
Editeaza .env cu datele tale.

### 2. Launch Infrastructure (Docker)
docker-compose down -v
docker-compose up -d

### 3. Start the Backend
cd backend
pip install -r requirements.txt
uv run uvicorn main:app --reload

### 4. Start the Frontend
cd frontend
flutter pub get
flutter run
flutter run -d chrome --web-port=3000