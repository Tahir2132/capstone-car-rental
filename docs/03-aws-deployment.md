# 03 – AWS deployment

Everything was created in the **AWS Management Console**, region **us-east-1 (N. Virginia)**.

Overview of all resources: [infrastructure/aws-resources.md](../infrastructure/aws-resources.md)

## Step 1 – S3: host the website

1. **S3 → Create bucket**, name `capston-rentalcar`, region us-east-1.
2. Upload `index.html`, `style.css` and `app.js` to the top level of the bucket.
3. Create a folder `images` and upload the car photos, named after the vehicle ID (`HH-001.jpg`, `HH-002.jpg` …).
4. **Properties → Static website hosting → Enable**, index document `index.html`.
5. **Permissions → Bucket policy**: allow read access only from my own IP address (for testing).
   Policy: [infrastructure/bucket-policy.json](../infrastructure/bucket-policy.json)

![S3 bucket](images/01-s3-bucket.png)

Bucket structure:

```
capston-rentalcar/
├── index.html
├── style.css
├── app.js
└── images/
    ├── HH-001.jpg
    └── …
```

## Step 2 – DynamoDB: store the car data

1. **DynamoDB → Create table**, name `Fleet`, partition key `location` (String), sort key `vehicleId` (String).
2. Open **CloudShell**, upload `backend/cars.json` and `backend/load_cars.py`.
3. Run:
   ```bash
   python3 load_cars.py
   ```
   Output: `10 cars loaded into Fleet`
4. Check under **Explore table items** that all 10 cars are there.

> 📸 Add screenshot: `images/02-dynamodb-items.png`

## Step 3 – Lambda: the search function

1. **Lambda → Create function → Author from scratch**, name `VehicleSearchFunction`, runtime **Python 3.12**.
2. Paste the code from [`backend/lambda_function.py`](../backend/lambda_function.py) and click **Deploy**.
3. **Configuration → Environment variables**: `TABLE_NAME` = `Fleet`.
4. **Configuration → General configuration**: timeout **10 seconds** (the default of 3 seconds was too short on the first run).
5. **Configuration → Permissions** → click the role name → **Add permissions → Attach policies** → `AmazonDynamoDBReadOnlyAccess`.

![Lambda permissions](images/03-lambda-permissions.png)

6. **Test** tab with the event from [infrastructure/lambda-test-event.json](../infrastructure/lambda-test-event.json). Result: `statusCode 200` with 4 Hamburg cars.

> 📸 Add screenshot: `images/03-lambda-test.png`

## Step 4 – API Gateway: the public API

1. **API Gateway → Create API → HTTP API → Build**.
2. Integration: **Lambda** → `VehicleSearchFunction`, API name `car-rental-api`.

   ![API integration](images/04-api-integration.png)

3. Route: **GET** `/api/vehicles` → `VehicleSearchFunction`.

   ![API route](images/04-api-route.png)

4. Stage `$default` with auto-deploy, then **Create**.

   ![API review](images/04-api-review.png)

5. **CORS → Configure**: Allow-Origin `*`, Allow-Methods `GET`, Allow-Headers `*`.

   ![CORS](images/04-api-cors.png)

6. Test in the browser:
   ```
   https://<api-id>.execute-api.us-east-1.amazonaws.com/api/vehicles?location=Hamburg&from=2026-11-01&to=2026-11-05
   ```

   ![API test](images/04-api-test.png)

## Step 5 – Connect the website to the API

In `frontend/app.js`, set the Invoke URL of the API:

```js
const API_URL = ["localhost", "127.0.0.1"].includes(location.hostname)
  ? "/api/vehicles"
  : "https://<api-id>.execute-api.us-east-1.amazonaws.com/api/vehicles";
```

Upload `app.js` to the bucket again.

## Step 6 – Test the whole flow

Open the S3 website URL, press **Ctrl+F5**, search for Hamburg.

![Result](images/06-website-result.png)

## Step 7 – Next: CloudFront

Put CloudFront in front of S3 and API Gateway for HTTPS, a private bucket (OAC) and one single address. See the planned diagram in [01-architecture.md](01-architecture.md).
