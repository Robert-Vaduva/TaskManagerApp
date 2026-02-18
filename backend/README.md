Go to Terminal and open /backend
uv run uvicorn main:app --reload
uvicorn main:app --host 0.0.0.0 --port 8000 --reload (to run APP on iPhone)
pip freeze > requirements.txt

Docker commands:
docker-compose down -v
docker-compose up -d

Erase all data and restart
docker-compose down 
docker system prune -a --volumes
docker-compose up -d
docker exec -it myfirstapp-db-1 psql -U devbrosrob -d app_comerciala  -c "SELECT * FROM users;"
docker exec -it taskmanagerapp-db-1 psql -U devbrosrob -d taskmanager -c "DROP TABLE tasks;"

Logger:
from app.core.logger import logger
logger.info("Cineva a încercat să se logheze")
logger.error(f"Eroare critică la login: {str(e)}")

Flutter:
cd frontend
flutter pub get
flutter run
flutter run -d chrome --web-port=3000