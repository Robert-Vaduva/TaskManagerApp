"""
security.py
"""
import secrets
import hashlib
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    """
    Get password hash
    :param password:
    :return:
    """
    salt = secrets.token_hex(8)
    hash_obj = hashlib.sha256(f"{password}{salt}".encode())
    return f"{salt}.{hash_obj.hexdigest()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify password
    :param plain_password:
    :param hashed_password:
    :return:
    """
    try:
        salt, original_hash = hashed_password.split(".")
        new_hash = hashlib.sha256(f"{plain_password}{salt}".encode()).hexdigest()
        return new_hash == original_hash
    except ValueError:
        return False
