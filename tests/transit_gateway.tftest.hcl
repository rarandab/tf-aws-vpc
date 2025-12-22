mock_provider "aws" {}

variables {
  name_prefix           = "test"
  region                = "eu-west-1"
  availability_zone_ids = ["euw1-az1", "euw1-az2"]
  cidr_blocks                 = ["10.0.0.0/20"]
  subnet_layers = {
    pri = {
      cidr_blocks = ["10.0.0.0/25", "10.0.0.128/25"]
    }
    netatt = {
      cidr_blocks = ["10.0.2.0/28", "10.0.2.16/28"]
      is_netatt   = true
    }
  }
  transit_gateway_attach = {
    id                                 = "tgw-0123456789abcdef0"
    appliance_mode_support             = true
    dns_support                        = true
    security_group_referencing_support = false
    routes = {
      pri = ["192.168.0.0/16", "pl-0123456789abcdef0"]
    }
  }
}

run "transit_gateway_attachment" {
  command = apply

  # VPC assertions
  assert {
    condition     = aws_vpc.this.region == "eu-west-1"
    error_message = "VPC region does not match expected value"
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/20"
    error_message = "VPC CIDR block should be 10.0.0.0/20"
  }

  assert {
    condition     = aws_vpc.this.tags.Name == "test-vpc"
    error_message = "VPC name tag should follow naming convention"
  }

  # Private subnet assertions
  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private : subnet.vpc_id == aws_vpc.this.id
    ])
    error_message = "All private subnets should belong to the VPC"
  }

  # Network attachment subnet assertions
  assert {
    condition     = length(aws_subnet.netatt) == 2
    error_message = "Should create 2 netatt subnets for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.netatt : subnet.vpc_id == aws_vpc.this.id
    ])
    error_message = "All netatt subnets should belong to the VPC"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.netatt : subnet.region == "eu-west-1"
    ])
    error_message = "All netatt subnets should be in the correct region"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.netatt : can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All netatt subnets should have valid CIDR blocks"
  }

  # Transit Gateway attachment assertions
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 1
    error_message = "Should create 1 transit gateway attachment when transit_gateway_attach is configured"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].transit_gateway_id == "tgw-0123456789abcdef0"
    error_message = "Transit gateway attachment should reference the correct transit gateway ID"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].vpc_id == aws_vpc.this.id
    error_message = "Transit gateway attachment should reference the VPC ID"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].region == "eu-west-1"
    error_message = "Transit gateway attachment should be in the correct region"
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this[0].subnet_ids) == 2
    error_message = "Transit gateway attachment should use all netatt subnets"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].appliance_mode_support == "enable"
    error_message = "Transit gateway attachment should have appliance mode support enabled"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].dns_support == "enable"
    error_message = "Transit gateway attachment should have DNS support enabled"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].security_group_referencing_support == "disable"
    error_message = "Transit gateway attachment should have security group referencing support disabled"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].ipv6_support == "disable"
    error_message = "Transit gateway attachment should have IPv6 support disabled"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].tags.Name == "test-tga"
    error_message = "Transit gateway attachment name tag should follow naming convention"
  }

  # Route table assertions for netatt subnets
  assert {
    condition     = length(aws_route_table.netatt) == 2
    error_message = "Should create 2 netatt route tables for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for rt in aws_route_table.netatt : rt.vpc_id == aws_vpc.this.id
    ])
    error_message = "All netatt route tables should belong to the VPC"
  }

  # Route table associations for netatt subnets
  assert {
    condition     = length(aws_route_table_association.netatt) == 2
    error_message = "Should create 2 netatt route table associations"
  }

  # Network ACL assertions for netatt subnets
  assert {
    condition     = length(aws_network_acl.netatt) == 1
    error_message = "Should create 1 netatt network ACL for the netatt layer"
  }

  assert {
    condition = alltrue([
      for acl in aws_network_acl.netatt : acl.vpc_id == aws_vpc.this.id
    ])
    error_message = "All netatt network ACLs should belong to the VPC"
  }

  assert {
    condition     = length(aws_network_acl_association.netatt) == 2
    error_message = "Should create 2 netatt network ACL associations"
  }

  # Custom routes assertions (transit gateway routes)
  assert {
    condition     = length(aws_route.custom) > 0
    error_message = "Should create custom routes for transit gateway traffic"
  }

  # Verify routes point to transit gateway for private subnets
  assert {
    condition = alltrue([
      for route in aws_route.custom : route.transit_gateway_id != null ? route.transit_gateway_id == "tgw-0123456789abcdef0" : true
    ])
    error_message = "Transit gateway routes should point to the correct transit gateway ID"
  }

  # Verify specific route destinations
  assert {
    condition = anytrue([
      for route in aws_route.custom : route.destination_cidr_block == "192.168.0.0/16"
    ])
    error_message = "Should create route for 192.168.0.0/16 to transit gateway"
  }

  assert {
    condition = anytrue([
      for route in aws_route.custom : route.destination_prefix_list_id == "pl-0123456789abcdef0"
    ])
    error_message = "Should create route for prefix list pl-0123456789abcdef0 to transit gateway"
  }

  # Verify no public subnets are created
  assert {
    condition     = length(aws_subnet.public) == 0
    error_message = "Should not create public subnets when is_public is false"
  }

  # Verify no internet gateway is created
  assert {
    condition     = length(aws_internet_gateway.this) == 0
    error_message = "Should not create internet gateway when no public subnets or NAT gateway"
  }

  # Verify no NAT gateway is created
  assert {
    condition     = length(aws_nat_gateway.regional) == 0
    error_message = "Should not create regional NAT gateway when nat_gateway is null"
  }

  assert {
    condition     = length(aws_nat_gateway.zonal) == 0
    error_message = "Should not create zonal NAT gateways when nat_gateway is null"
  }

  # Verify no core network attachment
  assert {
    condition     = length(aws_networkmanager_vpc_attachment.this) == 0
    error_message = "Should not create core network attachment when core_network_attach is null"
  }
}

run "transit_gateway_minimal_config" {
  command = plan

  variables {
    transit_gateway_attach = {
      id = "tgw-0987654321fedcba0"
    }
  }

  # Transit Gateway attachment with minimal configuration
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 1
    error_message = "Should create 1 transit gateway attachment with minimal config"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].transit_gateway_id == "tgw-0987654321fedcba0"
    error_message = "Transit gateway attachment should reference the correct transit gateway ID"
  }

  # Default values for optional parameters
  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].appliance_mode_support == "disable"
    error_message = "Transit gateway attachment should have appliance mode support disabled by default"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].dns_support == "disable"
    error_message = "Transit gateway attachment should have DNS support disabled by default"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this[0].security_group_referencing_support == "disable"
    error_message = "Transit gateway attachment should have security group referencing support disabled by default"
  }

  # Verify no custom routes are created when routes are not specified
  assert {
    condition     = length(aws_route.custom) == 0
    error_message = "Should not create custom routes when routes are not specified"
  }
}
