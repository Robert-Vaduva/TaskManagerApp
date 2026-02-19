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

### 5. Run the APP on your iPhone
1. Network: 
both the iPhone and the Laptop have to be on the same network,
with all the devices being visible to one another (PA not GA)
Disable temporary the Firewall on your laptop and write down the IP assigned for this network
2. Backend:
change in backend/main.py → allow_origins=["*"] (to allow all connections)
start the backend from command line:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
3. Frontend:
change in frontend/lib/pages/auth_page.dart →  final String baseUrl = "http://192.168.178.112:8000/api/v1/auth";
change in frontend/lib/services/task_services.dart →    final String baseUrl = "http://192.168.178.112:8000/tasks";
start the frontend from command line:
flutter run and select your device from the list

### 6. Animations done with LottieFiles
https://lottiefiles.com/