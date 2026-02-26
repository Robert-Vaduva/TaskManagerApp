def test_register_user(client):
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "full_name": "Test User", "password": "password123"}
    )
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"


def test_login_success(client):
    client.post(
        "/api/v1/auth/register",
        json={"email": "login@example.com", "full_name": "Login User", "password": "password123"}
    )

    response = client.post(
        "/api/v1/auth/login",
        data={"username": "login@example.com", "password": "password123"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()