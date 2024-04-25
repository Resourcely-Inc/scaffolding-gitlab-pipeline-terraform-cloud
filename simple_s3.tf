module "simple_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "simple-s3-bucket"
  force_destroy = true
}
