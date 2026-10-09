"""
VehicleSearchFunction

Runs unchanged in two places:
  - locally:  local_server.py calls lambda_handler() and the cars come from cars.json
  - on AWS:   API Gateway (HTTP API) calls lambda_handler() and the cars come from
              DynamoDB, as soon as the environment variable TABLE_NAME is set.

Request:  GET /api/vehicles?location=Hamburg&from=2026-11-01&to=2026-11-05[&category=SUV]
Response: JSON with the matching cars and the total price for the rental period.
"""
import json
import os
from datetime import date
from decimal import Decimal

TABLE_NAME = os.environ.get("TABLE_NAME")          # set on AWS, empty locally
DATA_FILE = os.path.join(os.path.dirname(__file__), "cars.json")
MAX_DAYS = 30


def get_cars(location):
    """Return all cars at one location, from DynamoDB (AWS) or cars.json (local)."""
    if TABLE_NAME:
        import boto3
        from boto3.dynamodb.conditions import Key

        table = boto3.resource("dynamodb").Table(TABLE_NAME)
        # Query (not Scan): reads only the items of this one partition key
        kwargs = {"KeyConditionExpression": Key("location").eq(location)}
        items = []
        while True:
            page = table.query(**kwargs)
            items.extend(page["Items"])
            if "LastEvaluatedKey" not in page:
                return items
            kwargs["ExclusiveStartKey"] = page["LastEvaluatedKey"]

    with open(DATA_FILE, encoding="utf-8") as f:
        return [car for car in json.load(f) if car["location"] == location]


def to_json(value):
    """DynamoDB returns numbers as Decimal, which json.dumps cannot handle."""
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    raise TypeError(f"Cannot serialize {type(value)}")


def response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=to_json),
    }


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    location = (params.get("location") or "").strip()
    category = (params.get("category") or "").strip()

    # 1. Validate input: never trust what the browser sends
    if not location:
        return response(400, {"error": "Choose a pick-up location."})
    try:
        start = date.fromisoformat(params.get("from", ""))
        end = date.fromisoformat(params.get("to", ""))
    except ValueError:
        return response(400, {"error": "Enter dates in the format YYYY-MM-DD."})
    if start < date.today():
        return response(400, {"error": "The pick-up date can't be in the past."})

    # 2. Number of rental days
    days = (end - start).days
    if days < 1:
        return response(400, {"error": "The return date must be after the pick-up date."})
    if days > MAX_DAYS:
        return response(400, {"error": f"You can rent a car for up to {MAX_DAYS} days."})

    # 3. Get the cars and 4. calculate the price
    vehicles = []
    for car in get_cars(location):
        if category and car["category"] != category:
            continue
        car = dict(car)
        car["totalPrice"] = car["pricePerDay"] * days
        vehicles.append(car)
    vehicles.sort(key=lambda c: c["totalPrice"])

    # 5. Return the result
    return response(200, {
        "location": location,
        "from": start.isoformat(),
        "to": end.isoformat(),
        "days": days,
        "count": len(vehicles),
        "vehicles": vehicles,
    })
