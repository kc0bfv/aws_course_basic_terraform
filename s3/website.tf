terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21"
    }
  }
}

variable "bucket" {
  default = "website-test-NAME_HERE"
}

variable "website_dir" {
  default = "./content/"
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "${ var.website_dir }"
  template_vars = {
  }
}

resource "aws_s3_bucket" "website_test" {
  bucket = var.bucket
}

resource "aws_s3_bucket_acl" "website_test_acl" {
  bucket = aws_s3_bucket.website_test.bucket
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "website_test_policy" {
  bucket = aws_s3_bucket.website_test.bucket
  policy = templatefile("policy.json", { bucket = var.bucket })
}

resource "aws_s3_bucket_website_configuration" "website_test" {
  bucket = aws_s3_bucket.website_test.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Stolen from https://stackoverflow.com/questions/57456167/uploading-multiple-files-in-aws-s3-from-terraform
resource "aws_s3_object" "website_content" {
  #for_each = fileset("${var.website_dir}", "*")
  for_each = module.template_files.files

  bucket       = aws_s3_bucket.website_test.bucket
  key          = each.key
  content_type = each.value.content_type

  #source       = "${var.website_dir}${each.value}"
  source = each.value.source_path
  content = each.value.content
  etag = each.value.digests.md5

  #etag = filemd5("${var.website_dir}${each.value}")
}

output "website_endpoint" {
  value = aws_s3_bucket.website_test.website_endpoint
}
