terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.27.0"
      configuration_aliases = [aws.core_network]
    }
  }
}
