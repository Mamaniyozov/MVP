from locust import HttpUser, task, between

class FinanceAppUser(HttpUser):
    wait_time = between(1, 5)

    def on_start(self):
        # Register a new user
        import random
        import string
        self.username = ''.join(random.choices(string.ascii_lowercase, k=10))
        self.email = f"{self.username}@example.com"
        self.password = "password123"
        
        response = self.client.post("/api/v1/users/register/", json={
            "email": self.email,
            "password": self.password,
            "password_confirm": self.password,
            "first_name": "Test",
            "last_name": "User"
        })
        
        # Login
        response = self.client.post("/api/v1/users/login/", json={
            "email": self.email,
            "password": self.password
        })
        
        if response.status_code == 200:
            self.token = response.json().get("access")
            self.client.headers.update({"Authorization": f"Bearer {self.token}"})

    @task(3)
    def view_dashboard(self):
        self.client.get("/api/v1/analytics/dashboard/")

    @task(2)
    def view_transactions(self):
        self.client.get("/api/v1/transactions/")

    @task(1)
    def create_transaction(self):
        self.client.post("/api/v1/transactions/", json={
            "amount": 100,
            "type": "expense",
            "description": "Test Transaction"
        })
