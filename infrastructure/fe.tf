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

resource "aws_s3_bucket_policy" "web_bucket_policy" {
  bucket = aws_s3_bucket.web_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowGetObjects"
    Statement = [
      {
        Sid       = "AllowPublic"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_bucket.arn}/**"
      }
    ]
  })
}

locals {
  mime_types = {
    ".html" = "text/html"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
  }
}

resource "aws_s3_object" "upload_object" {
  for_each     = fileset("../fe/out/", "**")
  bucket       = aws_s3_bucket.web_bucket.id
  key          = each.value
  source       = "../fe/out/${each.value}"
  etag         = filemd5("../fe/out/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.key), null)
}