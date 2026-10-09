# Run in AWS CloudShell: python3 load_cars.py
# Loads all cars from cars.json into the DynamoDB table "Fleet".
import json
import boto3

table = boto3.resource("dynamodb").Table("Fleet")
with open("cars.json", encoding="utf-8") as f:
    cars = json.load(f)
with table.batch_writer() as batch:
    for car in cars:
        batch.put_item(Item=car)
print(f"{len(cars)} cars loaded into Fleet")
