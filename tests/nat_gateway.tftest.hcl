mock_provider "aws" {
  override_data {
    target = data.aws_availability_zone.this[0]
    values = {
      name_suffix = "a"
    }
  }
  override_data {
    target = data.aws_availability_zone.this[1]
    values = {
      name_suffix = "b"
    }
  }
}

variables {
  name_prefix           = "test"
  region                = "eu-west-1"
  availability_zone_ids = ["euw1-az1", "euw1-az2"]
  cidrs                 = ["10.0.0.0/20"]
  subnet_layers = {
    pri = {
      cidr_blocks = ["10.0.0.0/25", "10.0.0.128/25"]
    }
    pub = {
      cidr_blocks = ["10.0.1.0/25", "10.0.1.128/25"]
      is_public   = true
    }
  }
}

run "regional_nat_gateway" {
  command = apply

  variables {
    nat_gateway = {
      mode = "regional"
      routes = {
        pri = ["0.0.0.0/0", "192.168.0.0/16"]
      }
    }
  }

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

  # Regional NAT Gateway assertions
  assert {
    condition     = length(aws_nat_gateway.regional) == 1
    error_message = "Should create 1 regional NAT gateway when mode is regional"
  }

  assert {
    condition     = aws_nat_gateway.regional[0].region == "eu-west-1"
    error_message = "Regional NAT gateway should be in the correct region"
  }

  assert {
    condition     = aws_nat_gateway.regional[0].availability_mode == "regional"
    error_message = "Regional NAT gateway should have availability_mode set to regional"
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

  # Verify no EIPs are created for regional mode
  assert {
    condition     = length(aws_eip.ngw) == 0
    error_message = "Should not create EIPs for regional NAT gateway mode"
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

  # Custom routes assertions (NAT gateway routes)
  assert {
    condition     = length(aws_route.custom) > 0
    error_message = "Should create custom routes for NAT gateway traffic"
  }

  # Verify routes point to regional NAT gateway for private subnets
  assert {
    condition = anytrue([
      for route in aws_route.custom : route.destination_cidr_block == "0.0.0.0/0" && route.nat_gateway_id == aws_nat_gateway.regional[0].id
    ])
    error_message = "Default route should point to the regional NAT gateway"
  }

  assert {
    condition = anytrue([
      for route in aws_route.custom : route.destination_cidr_block == "192.168.0.0/16" && route.nat_gateway_id == aws_nat_gateway.regional[0].id
    ])
    error_message = "Custom route for 192.168.0.0/16 should point to the regional NAT gateway"
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
}

run "zonal_nat_gateway" {
  command = apply

  variables {
    nat_gateway = {
      mode         = "zonal"
      subnet_layer = "pub"
      routes = {
        pri = ["0.0.0.0/0"]
      }
    }
  }

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

  # Internet Gateway assertions
  assert {
    condition     = length(aws_internet_gateway.this) == 1
    error_message = "Should create 1 internet gateway when public subnets exist"
  }

  assert {
    condition     = aws_internet_gateway.this[0].vpc_id == aws_vpc.this.id
    error_message = "Internet gateway should be attached to the VPC"
  }

  # EIP assertions for zonal mode
  assert {
    condition     = length(aws_eip.ngw) == 2
    error_message = "Should create 2 EIPs for zonal NAT gateways (one per AZ)"
  }

  assert {
    condition = alltrue([
      for eip in aws_eip.ngw : eip.region == "eu-west-1"
    ])
    error_message = "All EIPs should be in the correct region"
  }

  # Zonal NAT Gateway assertions
  assert {
    condition     = length(aws_nat_gateway.zonal) == 2
    error_message = "Should create 2 zonal NAT gateways when mode is zonal (one per AZ)"
  }

  assert {
    condition = alltrue([
      for ngw in aws_nat_gateway.zonal : ngw.region == "eu-west-1"
    ])
    error_message = "All zonal NAT gateways should be in the correct region"
  }

  assert {
    condition = alltrue([
      for ngw in aws_nat_gateway.zonal : ngw.connectivity_type == "public"
    ])
    error_message = "All zonal NAT gateways should have connectivity_type set to public"
  }

  assert {
    condition = alltrue([
      for k, ngw in aws_nat_gateway.zonal : contains(keys(aws_eip.ngw), k)
    ])
    error_message = "Each zonal NAT gateway should have a corresponding EIP"
  }

  assert {
    condition = alltrue([
      for k, ngw in aws_nat_gateway.zonal : contains([for subnet in aws_subnet.public : subnet.id], ngw.subnet_id)
    ])
    error_message = "Each zonal NAT gateway should be in a public subnet"
  }

  # Verify naming convention for zonal NAT gateways
  assert {
    condition = alltrue([
      for k, ngw in aws_nat_gateway.zonal : can(regex("^test-ngw-[a-z]$", ngw.tags.Name))
    ])
    error_message = "Zonal NAT gateway name tags should follow naming convention with AZ suffix"
  }

  # Verify no regional NAT gateway is created
  assert {
    condition     = length(aws_nat_gateway.regional) == 0
    error_message = "Should not create regional NAT gateway when mode is zonal"
  }

  # Route table assertions for private subnets
  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Should create 2 private route tables for 2 availability zones"
  }

  # Custom routes assertions (NAT gateway routes)
  assert {
    condition     = length(aws_route.custom) > 0
    error_message = "Should create custom routes for NAT gateway traffic"
  }

  # Verify routes point to appropriate zonal NAT gateways
  assert {
    condition = alltrue([
      for route in aws_route.custom : route.destination_cidr_block == "0.0.0.0/0" ? contains([for ngw in aws_nat_gateway.zonal : ngw.id], route.nat_gateway_id) : true
    ])
    error_message = "Default routes should point to zonal NAT gateways"
  }

  # Verify each private subnet has a route to its corresponding zonal NAT gateway
  assert {
    condition = length([
      for route in aws_route.custom : route if route.destination_cidr_block == "0.0.0.0/0"
    ]) == 2
    error_message = "Should create 2 default routes (one per private subnet to its zonal NAT gateway)"
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
}
