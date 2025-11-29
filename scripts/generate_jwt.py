#!/usr/bin/env python3
"""
Generate JWT tokens for load testing
Usage: python generate_jwt.py <userId>
"""

import sys
import os
from datetime import datetime, timedelta
import jwt

def generate_token(user_id: str) -> str:
    """Generate JWT token valid for 24 hours"""
    secret = os.environ.get('JWT_SECRET')
    if not secret:
        raise ValueError("JWT_SECRET environment variable not set")
    
    now = datetime.utcnow()
    exp = now + timedelta(hours=24)
    
    payload = {
        'sub': user_id,
        'iat': now,
        'exp': exp
    }
    
    token = jwt.encode(payload, secret, algorithm='HS256')
    return token

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python generate_jwt.py <userId>", file=sys.stderr)
        sys.exit(1)
    
    user_id = sys.argv[1]
    token = generate_token(user_id)
    print(token)
