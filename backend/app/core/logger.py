import logging
import sys

# Configurare format: Data Ora | Nivel | Mesaj
LOG_FORMAT = "%(asctime)s | %(levelname)s | %(message)s"

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format=LOG_FORMAT,
        handlers=[
            logging.FileHandler("server.log"), # Salvează în fișier
            logging.StreamHandler(sys.stdout)  # Afișează și în terminal
        ]
    )
    return logging.getLogger("my_app")

logger = setup_logging()