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