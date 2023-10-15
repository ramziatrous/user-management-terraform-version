provider "aws" {
  region  = "eu-central-1"
  profile = "Ramzi"

}
locals {
  account_number = DEINE AWS ACCOUNT NUMBER
}


resource "aws_s3_bucket" "website" {
  bucket = "website-v001"
  force_destroy = true
  acl    = "private"
  website {
    index_document = "index.html"  
    error_document = "error.html"
  }

  tags = {
    Name = "WebsiteBucket"
  }
 
}


# resource "aws_s3_bucket_policy" "website" {
#   bucket = aws_s3_bucket.website.id

#   policy = jsonencode({
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "s3:GetObject",
#       "Resource": "arn:aws:s3:::website-v001/*",
#       "Principal": "*"
#     }
#   ]
# }

# )
# }

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



resource "aws_dynamodb_table" "user" {
  name         = "user"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "Name"
    type = "S"
  }
  global_secondary_index {
    name            = "NameIndex"
    hash_key        = "Name"
    projection_type = "ALL"
    write_capacity  = 5
    read_capacity   = 5
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          Service : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : "dynamodb:Query",
        "Resource" : "arn:aws:dynamodb:eu-central-1:${local.account_number}:table/user/index/NameIndex"
      },
      {
        Action : ["dynamodb:Scan", "dynamodb:DeleteItem", "dynamodb:PutItem"],
        Effect : "Allow",
        Resource : "arn:aws:dynamodb:eu-central-1:${local.account_number}:table/user"
      }
    ]
  })
}

resource "aws_lambda_function" "lambda_add" {
  filename      = "add.zip"
  function_name = "lambda_add"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "lambda_getall" {
  filename      = "getall.zip"
  function_name = "lambda_getall"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "lambda_getbyname" {
  filename      = "getbyname.zip"
  function_name = "lambda_getbyname"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "lambda_delete" {
  filename      = "delete.zip"
  function_name = "lambda_delete"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_apigatewayv2_api" "users_api" {
  name          = "users_api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_headers = ["*"]
    allow_methods = ["POST", "GET", "DELETE"]
  }
}
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.users_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_add_integration" {
  api_id             = aws_apigatewayv2_api.users_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda_add.invoke_arn
}

resource "aws_apigatewayv2_integration" "lambda_getall_integration" {
  api_id             = aws_apigatewayv2_api.users_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda_getall.invoke_arn
}

resource "aws_apigatewayv2_integration" "lambda_delete_integration" {
  api_id             = aws_apigatewayv2_api.users_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda_delete.invoke_arn
}

resource "aws_apigatewayv2_integration" "lambda_getbyname_integration" {
  api_id             = aws_apigatewayv2_api.users_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda_getbyname.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda_add_route" {
  api_id    = aws_apigatewayv2_api.users_api.id
  route_key = "POST /add"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_add_integration.id}"
}

resource "aws_apigatewayv2_route" "lambda_getall_route" {
  api_id    = aws_apigatewayv2_api.users_api.id
  route_key = "GET /getall"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_getall_integration.id}"
}

resource "aws_apigatewayv2_route" "lambda_delete_route" {
  api_id    = aws_apigatewayv2_api.users_api.id
  route_key = "DELETE /delete/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_delete_integration.id}"
}

resource "aws_apigatewayv2_route" "lambda_getbyname_route" {
  api_id    = aws_apigatewayv2_api.users_api.id
  route_key = "GET /getbyid/{name}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_getbyname_integration.id}"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda_add" {
  statement_id  = "AllowAPIGatewayInvokeAdd"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_add.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.users_api.execution_arn}/*/*/add"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda_getall" {
  statement_id  = "AllowAPIGatewayInvokeGetAll"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_getall.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.users_api.execution_arn}/*/*/getall"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda_getbyname" {
  statement_id  = "AllowAPIGatewayInvokeGetByName"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_getbyname.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.users_api.execution_arn}/*/*/getbyid/{name}"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda_delete" {
  statement_id  = "AllowAPIGatewayInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_delete.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.users_api.execution_arn}/*/*/delete/{userId}"
}
