import jwt
import datetime

# Same secret as in .env
SECRET = "Qw8v2pX3rT9bL6sN1eJ4kZ7uH5cD0aS2fG8mV3wB6yP1qR4tU9lE5jC7xF0zM2nA6"

payload = {
    "userId": "123e4567-e89b-12d3-a456-426614174000",
    "email": "test@example.com",
    "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
}

token = jwt.encode(payload, SECRET, algorithm="HS256")
print(token)
