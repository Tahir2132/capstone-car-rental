# ---------- Lambda: vehicle search ----------
data "archive_file" "search" {
  type        = "zip"
  source_file = "${local.backend_dir}/lambda_function.py"
  output_path = "${path.module}/build/vehicle_search.zip"
}

resource "aws_iam_role" "search" {
  name = "${var.project}-vehicle-search-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Least privilege: write logs ...
resource "aws_iam_role_policy_attachment" "search_logs" {
  role       = aws_iam_role.search.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ... and only Query the Fleet table
resource "aws_iam_role_policy" "search_dynamodb" {
  name = "fleet-query-only"
  role = aws_iam_role.search.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Query"]
      Resource = aws_dynamodb_table.fleet.arn
    }]
  })
}

resource "aws_cloudwatch_log_group" "search" {
  name              = "/aws/lambda/${var.project}-vehicle-search"
  retention_in_days = 14
}

resource "aws_lambda_function" "search" {
  function_name    = "${var.project}-vehicle-search"
  role             = aws_iam_role.search.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.search.output_path
  source_code_hash = data.archive_file.search.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.fleet.name }
  }

  depends_on = [aws_cloudwatch_log_group.search, aws_iam_role_policy_attachment.search_logs]
}
