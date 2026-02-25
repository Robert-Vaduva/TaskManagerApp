"""
logger.py
"""
import logging
import sys

LOG_FORMAT = "%(asctime)s | %(levelname)s | %(message)s"


def setup_logging():
    """
    Setup logging
    :return:
    """
    logging.basicConfig(
        level=logging.INFO,
        format=LOG_FORMAT,
        handlers=[
            logging.FileHandler("server.log"),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger("my_app")

logger = setup_logging()
