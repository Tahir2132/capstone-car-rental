# AWS resources

All resources are in region **us-east-1 (N. Virginia)**.

| Service | Name | Settings |
|---|---|---|
| S3 | `capston-rentalcar` | Static website hosting on, index document `index.html`, bucket policy: [bucket-policy.json](bucket-policy.json) |
| DynamoDB | `Fleet` | Partition key `location` (String), sort key `vehicleId` (String), on-demand |
| Lambda | `VehicleSearchFunction` | Python 3.12, handler `lambda_function.lambda_handler`, timeout 10 s, env `TABLE_NAME=Fleet` |
| IAM | `VehicleSearchFunction-role-…` | `AWSLambdaBasicExecutionRole` (logs) + `AmazonDynamoDBReadOnlyAccess` |
| API Gateway | `car-rental-api` (HTTP API) | Route `GET /api/vehicles` → Lambda, stage `$default` (auto-deploy), CORS: origin `*`, methods `GET` |
| CloudWatch | `/aws/lambda/VehicleSearchFunction` | Lambda logs, created automatically |
