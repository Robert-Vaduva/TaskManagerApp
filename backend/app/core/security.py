from passlib.context import CryptContext
import secrets
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    """Creează un hash SHA-256 cu un salt aleatoriu."""
    salt = secrets.token_hex(8)
    hash_obj = hashlib.sha256(f"{password}{salt}".encode())
    return f"{salt}.{hash_obj.hexdigest()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifică dacă parola introdusă corespunde cu hash-ul stocat."""
    try:
        salt, original_hash = hashed_password.split(".")
        new_hash = hashlib.sha256(f"{plain_password}{salt}".encode()).hexdigest()
        return new_hash == original_hash
    except ValueError:
        return False