from locust import HttpUser, task, between

class FinanceAppUser(HttpUser):
    wait_time = between(1, 5)
    
    def on_start(self):
        """
        Executed when a user starts. We simulate logging in to get an auth token.
        """
        # Note: In a real load test, use diverse user credentials or a test database.
        response = self.client.post("/api/v1/auth/login/", json={
            "email": "test@example.com",
            "password": "testpassword123"
        })
        
        self.logged_in = False
        
        if response.status_code == 200:
            data = response.json()
            if data.get("mfa_required"):
                # If MFA is required, we simulate verifying MFA
                temp_token = data.get("temp_token")
                mfa_response = self.client.post("/api/v1/auth/mfa/verify/", json={
                    "token": "123456",  # A static valid code for testing environment, or bypass in test DB
                    "temp_token": temp_token
                })
                if mfa_response.status_code == 200:
                    self.logged_in = True
            else:
                self.logged_in = True

    @task(3)
    def view_dashboard(self):
        if self.logged_in:
            self.client.get("/api/v1/analytics/dashboard-summary/")

    @task(2)
    def view_transactions(self):
        if self.logged_in:
            self.client.get("/api/v1/transactions/")
            
    @task(1)
    def view_categories(self):
        if self.logged_in:
            self.client.get("/api/v1/categories/")
