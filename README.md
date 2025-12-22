# tf-aws-vpc
Terraform AWS VPC module

## Description

This Terraform module creates a comprehensive AWS VPC infrastructure with support for multiple networking patterns and advanced AWS networking services.

### Key Features

- **Multi-AZ VPC**: Creates a VPC across multiple availability zones with customizable CIDR blocks
- **Flexible Subnet Layers**: Supports multiple subnet tiers (public, private, network attachment) with configurable CIDR allocation
- **NAT Gateway Options**: Configurable NAT Gateway deployment in regional or zonal modes for outbound internet connectivity
- **Transit Gateway Integration**: Optional attachment to AWS Transit Gateway for multi-VPC connectivity
- **AWS Cloud WAN Support**: Optional integration with AWS Cloud WAN via Network Manager VPC attachments
- **Advanced Routing**: Customizable route tables with per-AZ or shared routing configurations
- **Network ACLs**: Automatic creation and association of Network ACLs for different subnet tiers
- **DHCP Options**: Configurable DHCP options for custom DNS and domain settings
- **DNS Configuration**: Built-in support for DNS hostnames and resolution within the VPC

### Use Cases

- **Hub and Spoke Networks**: Central VPC with Transit Gateway connectivity to multiple spoke VPCs
- **Multi-Tier Applications**: Separate subnet layers for web, application, and database tiers
- **Hybrid Cloud**: Integration with on-premises networks via Transit Gateway or Cloud WAN
- **Microservices Architecture**: Network segmentation for containerized workloads with EKS/ECS
- **Enterprise Networking**: Scalable VPC design for large organizations with multiple AWS accounts

## Example Usage
### Basic multi-tier VPC with regional NAT Gateway
This example demonstrates creating a basic multi-tier VPC with public, private, and database subnet layers across multiple availability zones, with regional NAT Gateway for outbound internet connectivity from private subnets.

```hcl
module "vpc" {
  source = "git::https://github.com/rarandab/tf-aws-vpc"

  name_prefix           = "example"
  region                = "us-west-2"
  availability_zone_ids = ["usw2-az1", "usw2-az2"]
  cidrs                 = ["10.0.0.0/16"]

  subnet_layers = {
    public = {
      cidr_block = "10.0.0.0/20"
      is_public  = true
    }
    private = {
      cidr_block = "10.0.16.0/20"
      is_public  = false
    }
    database = {
      cidr_block = "10.0.32.0/20"
      is_public  = false
    }
  }

  nat_gateway = {
    mode         = "regional"
    subnet_layer = "public"
  }

  config = {
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
}
```

### VPC with AWS Cloud WAN Core Network Integration
This example shows how to connect a VPC to an AWS Cloud WAN Core Network with a specific routing policy label for advanced network segmentation and routing policies.

```hcl
module "vpc" {
  source = "git::https://github.com/rarandab/tf-aws-vpc"

  name_prefix           = "cloudwan-vpc"
  region                = "us-west-2"
  availability_zone_ids = ["usw2-az1", "usw2-az2"]
  cidrs                 = ["10.1.0.0/16"]

  subnet_layers = {
    public = {
      cidr_block = "10.1.0.0/20"
      is_public  = true
    }
    private = {
      cidr_block = "10.1.16.0/20"
      is_public  = false
    }
    netatt = {
      cidr_block = "10.1.240.0/24"
      is_netatt  = true
    }
  }

  core_network_attach = {
    id                   = "core-network-12345678"
    arn                  = "arn:aws:networkmanager::123456789012:core-network/core-network-12345678"
    routing_policy_label = "production"
    dns_support          = true
    routes = {
      private = ["0.0.0.0/0"]
    }
    tags = {
      Environment = "production"
      Team        = "networking"
    }
  }

  config = {
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
}


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.27.0 |
## Providers

| Name | Version |
|------|---------|
| aws | >= 6.27.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability\_zone\_ids | List of availability zone IDs | `list(string)` | n/a | yes |
| cidr\_blocks | VPC CIDRs | `list(string)` | n/a | yes |
| config | A configuration object for the VPC. | <pre>object({<br/>    enable_dns_hostnames = optional(bool, true)<br/>    enable_dns_support   = optional(bool, true)<br/>  })</pre> | `{}` | no |
| core\_network\_attach | Core network parameters for the VPC | <pre>object({<br/>    id                                 = string<br/>    arn                                = string<br/>    tags                               = optional(map(string), {})<br/>    routing_policy_label               = optional(string)<br/>    appliance_mode_support             = optional(bool, false)<br/>    dns_support                        = optional(bool, false)<br/>    security_group_referencing_support = optional(bool, false)<br/>    routes                             = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
| dhcp\_options | DHCP options parameters for the VPC | <pre>object({<br/>    domain_name          = optional(string, null)<br/>    domain_name_servers  = optional(list(string), ["AmazonProvidedDNS"])<br/>    ntp_servers          = optional(list(string))<br/>    netbios_name_servers = optional(list(string))<br/>    netbios_node_type    = optional(number)<br/>  })</pre> | `{}` | no |
| flow\_logs | Flow Logs configuration | <pre>object({<br/>    retention_in_days = optional(number, 30)<br/>    iam_role_arn      = optional(string)<br/>    kms_key_arn       = optional(string)<br/>    log_format        = optional(string)<br/>    tags              = optional(map(string), {})<br/>  })</pre> | `null` | no |
| name\_prefix | Name prefix for the resources | `string` | n/a | yes |
| nat\_gateway | NAT Gateway configuration | <pre>object({<br/>    mode         = optional(string, "regional")<br/>    subnet_layer = optional(string)<br/>    routes       = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
| region | AWS region for all resources | `string` | n/a | yes |
| route\_table\_per\_az | Create a route table per availability zone | `bool` | `false` | no |
| subnet\_layers | List of subnet layer configurations | <pre>map(object({<br/>    cidr_block  = optional(string)<br/>    cidr_blocks = optional(list(string), [])<br/>    is_public   = optional(bool, false)<br/>    is_netatt   = optional(bool, false)<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| transit\_gateway\_attach | values for the transit gateway attachment | <pre>object({<br/>    id                                 = string<br/>    appliance_mode_support             = optional(bool, false)<br/>    dns_support                        = optional(bool, false)<br/>    security_group_referencing_support = optional(bool, false)<br/>    routes                             = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
## Outputs

| Name | Description |
|------|-------------|
| core\_network\_attachment | Core network attachment attributes |
| flowlogs\_cwlg | Cloudwatch LogGroup for VPC Flow Logs |
| network\_acls | Network ACLs attributes |
| route\_tables | Route tables attributes |
| subnets | Subnets attributes |
| transit\_gateway\_attachment | Transit gateway attachment attributes |
| vpc | VPC attributes |
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.permissions_cw_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.permissions_kms_flog_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.regional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.zonal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.netatt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_association.netatt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_networkmanager_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_vpc_attachment) | resource |
| [aws_route.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.netatt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.netatt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.netatt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_availability_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.permissions_cw_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.permissions_kms_flog_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->