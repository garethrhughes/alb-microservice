resource "null_resource" "build_next_app" {
  provisioner "local-exec" {
    command = <<EOT
       cd ../fe/
       npm install && npm run build 
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_s3_bucket" "web_bucket" {
  bucket = "microsite-web-bucket-dev"
}

resource "aws_s3_bucket_website_configuration" "microsite_web_bucket" {
  bucket = aws_s3_bucket.web_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.web_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "upload_object" {
  for_each      = fileset("../fe/out/", "*")
  bucket        = aws_s3_bucket.web_bucket.id
  key           = each.value
  source        = "../fe/out/${each.value}"
  etag          = filemd5("../fe/out/${each.value}")
}