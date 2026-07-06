data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

data "archive_file" "app_bundle" {
  type        = "zip"
  output_path = "${path.module}/app-bundle.zip"
  source_dir  = path.module
  excludes    = ["*.tf", "*.tfvars", "*.zip", ".terraform"]
}

resource "aws_s3_object" "app_bundle" {
  bucket = "dep-229209687346-us-east-1-an"
  key    = "eb-demo/app-bundle.zip"
  source = data.archive_file.app_bundle.output_path
  etag   = data.archive_file.app_bundle.output_md5
}

resource "aws_elastic_beanstalk_application_version" "v1" {
  name        = "v1-arm64-docker"
  application = module.elastic-beanstalk-application.elastic_beanstalk_application_name
  bucket      = aws_s3_object.app_bundle.bucket
  key         = aws_s3_object.app_bundle.key
}

module "elastic-beanstalk-application" {
  source  = "cloudposse/elastic-beanstalk-application/aws"
  version = "0.12.1"
  name    = var.app_name
}

module "elastic-beanstalk-environment" {
  source  = "cloudposse/elastic-beanstalk-environment/aws"
  version = "0.53.0"

  name                               = "${var.app_name}-env"
  description                        = var.description
  region                             = var.region
  elastic_beanstalk_application_name = module.elastic-beanstalk-application.elastic_beanstalk_application_name
  environment_type                   = "SingleInstance"
  rolling_update_enabled             = "false"
  instance_type                      = var.instance_type
  version_label                      = aws_elastic_beanstalk_application_version.v1.name
  vpc_id                             = data.aws_vpc.default.id
  application_subnets                = data.aws_subnets.default.ids
  solution_stack_name                = "64bit Amazon Linux 2023 v4.13.3 running Docker"
}