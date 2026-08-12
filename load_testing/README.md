# Load Testing

This directory contains the necessary files to perform load testing using Locust on the Finance MVP application.

## Prerequisites
1. Ensure the backend application is running.
2. Install the requirements for load testing.

```bash
cd load_testing
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
pip install -r requirements.txt
```

## Running the Tests
To run Locust in web mode (with UI):
```bash
locust
```
Then navigate to `http://localhost:8089` in your browser. Set the target host to your backend URL (e.g. `http://localhost:8000`).

To run without UI (headless mode):
```bash
locust --headless -u 100 -r 10 --run-time 1m -H http://localhost:8000
```
This spawns 100 users at a rate of 10 users/sec and runs the test for 1 minute against `http://localhost:8000`.

## Test Scenarios
The `locustfile.py` defines `FinanceAppUser` which performs:
- User Registration & Login (once on start)
- Viewing Dashboard (weight 3)
- Viewing Transactions (weight 2)
- Creating Transactions (weight 1)
