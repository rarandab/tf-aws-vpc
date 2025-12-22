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
  }
}

run "private" {
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
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled by default"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "VPC should have DNS support enabled by default"
  }

  assert {
    condition     = aws_vpc.this.tags.Name == "test-vpc"
    error_message = "VPC name tag should follow naming convention"
  }

  # DHCP Options assertions
  assert {
    condition     = aws_vpc_dhcp_options.this.region == "eu-west-1"
    error_message = "DHCP options region should match VPC region"
  }

  assert {
    condition     = contains(aws_vpc_dhcp_options.this.domain_name_servers, "AmazonProvidedDNS")
    error_message = "DHCP options should include AmazonProvidedDNS by default"
  }

  assert {
    condition     = aws_vpc_dhcp_options.this.tags.Name == "test-dop"
    error_message = "DHCP options name tag should follow naming convention"
  }

  # DHCP Options Association assertion
  assert {
    condition     = aws_vpc_dhcp_options_association.this.vpc_id == aws_vpc.this.id
    error_message = "DHCP options should be associated with the VPC"
  }

  assert {
    condition     = aws_vpc_dhcp_options_association.this.dhcp_options_id == aws_vpc_dhcp_options.this.id
    error_message = "DHCP options association should reference the correct DHCP options"
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

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private : subnet.region == "eu-west-1"
    ])
    error_message = "All private subnets should be in the correct region"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private : can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All private subnets should have valid CIDR blocks"
  }

  # Route table assertions for private subnets
  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Should create 2 private route tables for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for rt in aws_route_table.private : rt.vpc_id == aws_vpc.this.id
    ])
    error_message = "All private route tables should belong to the VPC"
  }

  # Route table association assertions
  assert {
    condition     = length(aws_route_table_association.private) == 2
    error_message = "Should create 2 private route table associations"
  }

  # Network ACL assertions for private subnets
  assert {
    condition     = length(aws_network_acl.private) == 1
    error_message = "Should create 1 private network ACL for the pri layer"
  }

  assert {
    condition = alltrue([
      for acl in aws_network_acl.private : acl.vpc_id == aws_vpc.this.id
    ])
    error_message = "All private network ACLs should belong to the VPC"
  }

  assert {
    condition     = length(aws_network_acl_association.private) == 2
    error_message = "Should create 2 private network ACL associations"
  }

  # Verify no public subnets are created (since is_public is not set)
  assert {
    condition     = length(aws_subnet.public) == 0
    error_message = "Should not create public subnets when is_public is false"
  }

  # Verify no netatt subnets are created (since is_netatt is not set)
  assert {
    condition     = length(aws_subnet.netatt) == 0
    error_message = "Should not create netatt subnets when is_netatt is false"
  }

  # Verify no internet gateway is created (since no public subnets and no NAT gateway)
  assert {
    condition     = length(aws_internet_gateway.this) == 0
    error_message = "Should not create internet gateway when no public subnets or NAT gateway"
  }

  # Verify no NAT gateway is created (since nat_gateway is null)
  assert {
    condition     = length(aws_nat_gateway.regional) == 0
    error_message = "Should not create regional NAT gateway when nat_gateway is null"
  }

  assert {
    condition     = length(aws_nat_gateway.zonal) == 0
    error_message = "Should not create zonal NAT gateways when nat_gateway is null"
  }

  # Verify no core network attachment (since core_network_attach is null)
  assert {
    condition     = length(aws_networkmanager_vpc_attachment.this) == 0
    error_message = "Should not create core network attachment when core_network_attach is null"
  }

  # Verify no transit gateway attachment (since transit_gateway_attach is null)
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0
    error_message = "Should not create transit gateway attachment when transit_gateway_attach is null"
  }
}

run "public" {
  command = apply

  variables {
    subnet_layers = {
      pri = {
        cidr_blocks = ["10.0.0.0/25", "10.0.0.128/25"]
      }
      pub = {
        cidr_block = "10.0.1.0/24"
        is_public  = true
      }
    }
    nat_gateway = {
      mode = "regional"
      routes = {
        pri = ["0.0.0.0/0"]
      }
    }
  }

  # VPC assertions (same as basic_vpc)
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

  # Public subnet assertions
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.public : subnet.vpc_id == aws_vpc.this.id
    ])
    error_message = "All public subnets should belong to the VPC"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.public : subnet.map_public_ip_on_launch == true
    ])
    error_message = "All public subnets should have map_public_ip_on_launch enabled"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.public : subnet.region == "eu-west-1"
    ])
    error_message = "All public subnets should be in the correct region"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.public : can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All public subnets should have valid CIDR blocks"
  }

  # Internet Gateway assertions
  assert {
    condition     = length(aws_internet_gateway.this) == 1
    error_message = "Should create 1 internet gateway when public subnets exist"
  }

  assert {
    condition     = aws_internet_gateway.this[0].vpc_id == aws_vpc.this.id
    error_message = "Internet gateway should be attached to the VPC"
  }

  assert {
    condition     = aws_internet_gateway.this[0].tags.Name == "test-igw"
    error_message = "Internet gateway name tag should follow naming convention"
  }

  # NAT Gateway assertions (regional mode)
  assert {
    condition     = length(aws_nat_gateway.regional) == 1
    error_message = "Should create 1 regional NAT gateway when mode is regional"
  }

  assert {
    condition     = aws_nat_gateway.regional[0].region == "eu-west-1"
    error_message = "Regional NAT gateway should be in the correct region"
  }

  assert {
    condition     = aws_nat_gateway.regional[0].tags.Name == "test-ngw"
    error_message = "Regional NAT gateway name tag should follow naming convention"
  }

  # Verify no zonal NAT gateways are created
  assert {
    condition     = length(aws_nat_gateway.zonal) == 0
    error_message = "Should not create zonal NAT gateways when mode is regional"
  }

  # Route table assertions for public subnets
  assert {
    condition     = length(aws_route_table.public) == 2
    error_message = "Should create 2 public route tables for 2 availability zones"
  }

  assert {
    condition = alltrue([
      for rt in aws_route_table.public : rt.vpc_id == aws_vpc.this.id
    ])
    error_message = "All public route tables should belong to the VPC"
  }

  # Route table associations for public subnets
  assert {
    condition     = length(aws_route_table_association.public) == 2
    error_message = "Should create 2 public route table associations"
  }

  # Network ACL assertions for public subnets
  assert {
    condition     = length(aws_network_acl.public) == 1
    error_message = "Should create 1 public network ACL for the pub layer"
  }

  assert {
    condition = alltrue([
      for acl in aws_network_acl.public : acl.vpc_id == aws_vpc.this.id
    ])
    error_message = "All public network ACLs should belong to the VPC"
  }

  assert {
    condition     = length(aws_network_acl_association.public) == 2
    error_message = "Should create 2 public network ACL associations"
  }

  # Network ACL assertions for private subnets (still exists)
  assert {
    condition     = length(aws_network_acl.private) == 1
    error_message = "Should create 1 private network ACL for the pri layer"
  }

  assert {
    condition     = length(aws_network_acl_association.private) == 2
    error_message = "Should create 2 private network ACL associations"
  }

  # Custom routes assertions (NAT gateway routes)
  assert {
    condition     = length(aws_route.ngw) > 0
    error_message = "Should create custom routes for NAT gateway traffic"
  }

  # Verify routes point to NAT gateway for private subnets
  assert {
    condition = alltrue([
      for route in aws_route.ngw : route.destination_cidr_block == "0.0.0.0/0" ? route.nat_gateway_id == aws_nat_gateway.regional[0].id : true
    ])
    error_message = "Default routes should point to the regional NAT gateway"
  }

  # Verify no netatt subnets are created
  assert {
    condition     = length(aws_subnet.netatt) == 0
    error_message = "Should not create netatt subnets when is_netatt is false"
  }

  # Verify no core network attachment
  assert {
    condition     = length(aws_networkmanager_vpc_attachment.this) == 0
    error_message = "Should not create core network attachment when core_network_attach is null"
  }

  # Verify no transit gateway attachment
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0
    error_message = "Should not create transit gateway attachment when transit_gateway_attach is null"
  }

  # Verify EIP count (should be 0 for regional NAT gateway)
  assert {
    condition     = length(aws_eip.ngw) == 0
    error_message = "Should not create EIPs for regional NAT gateway mode"
  }
}
