from passlib.context import CryptContext
import secrets
import hashlib

# Configurăm algoritmul de hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """Creează un hash SHA-256 cu un salt aleatoriu."""
    # Generăm un salt (un șir aleatoriu) pentru securitate sporită
    salt = secrets.token_hex(8)
    # Combinăm parola cu salt-ul
    hash_obj = hashlib.sha256(f"{password}{salt}".encode())
    # Returnăm salt-ul și hash-ul împreună, separate prin punct
    return f"{salt}.{hash_obj.hexdigest()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifică dacă parola introdusă corespunde cu hash-ul stocat."""
    try:
        # Extragem salt-ul și hash-ul original
        salt, original_hash = hashed_password.split(".")
        # Recalculăm hash-ul pentru parola introdusă folosind același salt
        new_hash = hashlib.sha256(f"{plain_password}{salt}".encode()).hexdigest()
        return new_hash == original_hash
    except ValueError:
        return False