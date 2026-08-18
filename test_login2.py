import urllib.request
import json
import urllib.error

url = "http://localhost:8000/api/v1/auth/login/"
data = json.dumps({
    "email": "test2@example.com",
    "password": "StrongPassword123!"
}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Response:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Response:", e.read().decode('utf-8'))
