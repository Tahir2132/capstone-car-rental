# 02 – Local setup

Run the whole project on your PC before deploying to AWS.

## Requirements

- Python 3.10 or newer (on Windows tick **Add Python to PATH** during installation)
- No extra packages

## Start

```bash
cd capstone-car-rental
python local_server.py
```

On Windows, if `python` is not found, use `py local_server.py`.

Open **http://localhost:8000**. Stop the server with **Ctrl+C**.

## What runs locally

| Local | On AWS |
|---|---|
| `frontend/` | S3 bucket |
| `local_server.py` | API Gateway |
| `backend/lambda_function.py` | Lambda |
| `backend/cars.json` | DynamoDB |

`app.js` automatically uses the local server when the page is opened on `localhost`, and API Gateway everywhere else.

## Test the API locally

http://localhost:8000/api/vehicles?location=Hamburg&from=2026-11-01&to=2026-11-05
