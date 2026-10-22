# ---------- DynamoDB: the car fleet ----------
resource "aws_dynamodb_table" "fleet" {
  name         = "${var.project}-fleet"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "location"
  range_key    = "vehicleId"

  attribute {
    name = "location"
    type = "S"
  }
  attribute {
    name = "vehicleId"
    type = "S"
  }
}

# Load the cars from ../backend/cars.json
locals {
  cars = { for car in jsondecode(file("${local.backend_dir}/cars.json")) : car.vehicleId => car }
}

resource "aws_dynamodb_table_item" "cars" {
  for_each   = local.cars
  table_name = aws_dynamodb_table.fleet.name
  hash_key   = aws_dynamodb_table.fleet.hash_key
  range_key  = aws_dynamodb_table.fleet.range_key

  # Numbers become DynamoDB "N", everything else "S"
  item = "{${join(",", [
    for k, v in each.value :
    "${jsonencode(k)}:${can(v + 0) ? jsonencode({ N = tostring(v) }) : jsonencode({ S = tostring(v) })}"
  ])}}"
}
