terraform {
  backend "s3" {
    bucket         = "dep-229209687346-us-east-1-an"
    key            = "eb-demo/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}