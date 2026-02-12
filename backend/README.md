Go to Terminal and open /backend
uv run uvicorn main:app --reload
pip freeze > requirements.txt

Docker commands:
docker-compose down -v
docker-compose up -d

Erase all data and restart
docker-compose down 
docker system prune -a --volumes
docker-compose up -d
docker exec -it myfirstapp-db-1 psql -U devbrosrob -d app_comerciala  -c "SELECT * FROM users;"

Logger:
from app.core.logger import logger
logger.info("Cineva a încercat să se logheze")
logger.error(f"Eroare critică la login: {str(e)}")
