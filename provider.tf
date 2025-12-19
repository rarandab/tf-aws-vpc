# Provider configuration for testing
provider "aws" {
  region = "us-east-1"

  # Mock configuration for testing
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  # Use mock endpoints to prevent actual AWS API calls
  endpoints {
    ec2            = "http://localhost:4566"
    networkmanager = "http://localhost:4566"
  }
}
