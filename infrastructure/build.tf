resource "null_resource" "build_nest_lambda" {
  provisioner "local-exec" {
    working_dir = "../bff"
    command = <<EOT
       npm install && ncc build ./src/serverless.ts -o ./dist
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

resource "null_resource" "build_next_app" {
  provisioner "local-exec" {
    working_dir = "../fe"
    command = <<EOT
      npm install && npm run build 
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
