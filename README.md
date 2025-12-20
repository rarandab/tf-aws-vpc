# tf-aws-vpc
Terraform AWS VPC module

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
| cidrs | VPC CIDRs | `list(string)` | n/a | yes |
| config | A configuration object for the VPC. | <pre>object({<br/>    enable_dns_hostnames = optional(bool, true)<br/>    enable_dns_support   = optional(bool, true)<br/>  })</pre> | `{}` | no |
| core\_network\_attach | Core network parameters for the VPC | <pre>object({<br/>    id                                 = string<br/>    arn                                = string<br/>    tags                               = optional(map(string), {})<br/>    routing_policy_label               = optional(string)<br/>    appliance_mode_support             = optional(bool, false)<br/>    dns_support                        = optional(bool, false)<br/>    security_group_referencing_support = optional(bool, false)<br/>    routes                             = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
| dhcp\_options | DHCP options parameters for the VPC | <pre>object({<br/>    domain_name          = optional(string, null)<br/>    domain_name_servers  = optional(list(string), ["AmazonProvidedDNS"])<br/>    ntp_servers          = optional(list(string))<br/>    netbios_name_servers = optional(list(string))<br/>    netbios_node_type    = optional(number)<br/>  })</pre> | `{}` | no |
| name\_prefix | Name prefix for the resources | `string` | n/a | yes |
| nat\_gateway | NAT Gateway configuration | <pre>object({<br/>    mode         = optional(string, "regional")<br/>    subnet_layer = optional(string)<br/>    routes       = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
| region | AWS region for all resources | `string` | n/a | yes |
| route\_table\_per\_az | Create a route table per availability zone | `bool` | `false` | no |
| subnet\_layers | List of subnet layer configurations | <pre>map(object({<br/>    cidr_block  = optional(string)<br/>    cidr_blocks = optional(list(string), [])<br/>    is_public   = optional(bool, false)<br/>    is_netatt   = optional(bool, false)<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| transit\_gateway\_attach | values for the transit gateway attachment | <pre>object({<br/>    id                                 = string<br/>    appliance_mode_support             = optional(bool, false)<br/>    dns_support                        = optional(bool, false)<br/>    security_group_referencing_support = optional(bool, false)<br/>    routes                             = optional(map(list(string)), {})<br/>  })</pre> | `null` | no |
## Outputs

No outputs.
## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
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
<!-- END_TF_DOCS -->