from locust import HttpUser, task, between

class FinanceUser(HttpUser):
    wait_time = between(1, 5)

    @task(3)
    def view_health(self):
        self.client.get("/api/v1/health/")

    @task(1)
    def view_docs(self):
        self.client.get("/api/docs/")
