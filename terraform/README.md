# Capston Rent – Terraform

Builds the whole project: S3 + CloudFront (OAC), DynamoDB with 10 cars, Lambda, API Gateway (CORS, throttling), Cognito, and an optional budget alert.

```bash
cd terraform
terraform init
terraform plan
terraform apply          # optional: -var="alert_email=you@example.com"
```

Open `website_url` from the output after about 5 minutes.

After changing website files, run `terraform apply` again, then clear the CloudFront cache:

```bash
aws cloudfront create-invalidation --distribution-id <cloudfront_distribution_id> --paths "/*"
```

Remove everything: `terraform destroy`
