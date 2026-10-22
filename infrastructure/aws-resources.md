# AWS resources

Region **us-east-1 (N. Virginia)**; CloudFront is global.

| Service | Name | Settings |
|---|---|---|
| S3 | `capston-rentalcar` | Block all public access on; readable only by CloudFront ([bucket-policy.json](bucket-policy.json)) |
| CloudFront | `capston-rentalcar-website` | Origin: S3 bucket with OAC, redirect HTTP to HTTPS, default root object `index.html`, no WAF |
| Cognito | User pool `us-east-1_1FcDVHqrL`, app client `elbe-rent-web` | SPA, sign-in with email, self-registration on, managed login, callback and sign-out URL = CloudFront URL, authorization code grant, scopes `openid email` |
| DynamoDB | `Fleet` | Partition key `location`, sort key `vehicleId`, on-demand |
| Lambda | `VehicleSearchFunction` | Python 3.12, timeout 10 s, env `TABLE_NAME=Fleet` |
| IAM | `VehicleSearchFunction-role-…` | `AWSLambdaBasicExecutionRole` + `AmazonDynamoDBReadOnlyAccess` |
| API Gateway | `car-rental-api` (HTTP API) | `GET /api/vehicles` → Lambda, stage `$default`, CORS origin = CloudFront URL, method `GET` |
| CloudWatch | `/aws/lambda/VehicleSearchFunction` | Lambda logs |
