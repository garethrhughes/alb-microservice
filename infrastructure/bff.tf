resource "null_resource" "build_nest_lambda" {
  provisioner "local-exec" {
    command = <<EOT
       npm install ../bff/ && ncc build ../bff/src/serverless.ts -o ../bff/dist
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_dir  = "../bff/dist/"
  output_path = "./lambda.zip"
  depends_on  = [null_resource.build_nest_lambda]
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "microsite-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  runtime          = "nodejs22.x"
  depends_on       = [data.archive_file.lambda_archive]
  memory_size      = 256
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "microsite_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "microsite_lambda_log_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "microsite_lambda_log_policy" {
  name   = "microsite_lambda_log_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.microsite_lambda_log_policy_document.json
}

resource "aws_iam_role_policy_attachment" "microsite_lambda_log_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.microsite_lambda_log_policy.arn
}

resource "aws_iam_policy_attachment" "lambda_exec_attach" {
  name       = "lambda_exec_policy_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "microsite_api" {
  name          = "microsite-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.microsite_api.id

  name        = "default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.microsite_api_api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_cloudwatch_log_group" "microsite_api_api_gw" {
  name = "/aws/api-gw/${aws_apigatewayv2_api.microsite_api.name}"

  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.microsite_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda.arn
  payload_format_version = "2.0"
}

# Route for API Gateway
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.microsite_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.microsite_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.microsite_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.microsite_api.api_endpoint
}