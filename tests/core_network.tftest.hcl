mock_provider "aws" {
  override_resource {
    target = aws_vpc.this
    values = {
      arn = "arn:aws:logs::012345678901:vpc/test-vpc"
    }
  }
  override_resource {
    target = aws_subnet.netatt
    values = {
      arn = "arn:aws:logs::012345678901:subnet/test-irl-flowlogs"
    }
  }
}

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
  core_network_attach = {
    id                                 = "core-network-0123456789abcdef0"
    arn                                = "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0"
    appliance_mode_support             = false
    dns_support                        = true
    security_group_referencing_support = true
    routes = {
      pri = ["192.168.0.0/16", "172.16.0.0/12"]
    }
    tags = {
      Environment = "test"
      Purpose     = "core-network-attachment"
    }
  }
}

run "core_network_attachment" {
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

  # Core network attachment assertions
  assert {
    condition     = length(aws_networkmanager_vpc_attachment.this) == 1
    error_message = "Should create 1 core network attachment when core_network_attach is configured"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].core_network_id == "core-network-0123456789abcdef0"
    error_message = "Core network attachment should reference the correct core network ID"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].vpc_arn == aws_vpc.this.arn
    error_message = "Core network attachment should reference the VPC ARN"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].routing_policy_label == null
    error_message = "Core network attachment should have no routing policy label"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].appliance_mode_support == false
    error_message = "Core network attachment should have appliance mode support disabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].dns_support == true
    error_message = "Core network attachment should have DNS support enabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].security_group_referencing_support == true
    error_message = "Core network attachment should have security group referencing support enabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].ipv6_support == false
    error_message = "Core network attachment should have IPv6 support disabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Name == "test-cna"
    error_message = "Core network attachment name tag should follow naming convention"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Environment == "test"
    error_message = "Core network attachment should include custom tags"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Purpose == "core-network-attachment"
    error_message = "Core network attachment should include custom tags"
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

  # Custom routes assertions (core network routes)
  assert {
    condition     = length(aws_route.cwn) > 0
    error_message = "Should create custom routes for core network traffic"
  }

  # Verify routes point to core network for private subnets
  assert {
    condition = alltrue([
      for route in aws_route.cwn : route.core_network_arn != null ? route.core_network_arn == "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0" : true
    ])
    error_message = "Core network routes should point to the correct core network ARN"
  }

  # Verify specific route destinations
  assert {
    condition = anytrue([
      for route in aws_route.cwn : route.destination_cidr_block == "192.168.0.0/16"
    ])
    error_message = "Should create route for 192.168.0.0/16 to core network"
  }

  assert {
    condition = anytrue([
      for route in aws_route.cwn : route.destination_cidr_block == "172.16.0.0/12"
    ])
    error_message = "Should create route for 172.16.0.0/12 to core network"
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

  # Verify no transit gateway attachment
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0
    error_message = "Should not create transit gateway attachment when transit_gateway_attach is null"
  }
}

run "core_network_attachment_routing_policy" {
  command = apply

  variables {
    core_network_attach = {
      id                                 = "core-network-0123456789abcdef0"
      arn                                = "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0"
      routing_policy_label               = "test-routing-policy"
      appliance_mode_support             = false
      dns_support                        = true
      security_group_referencing_support = true
      routes = {
        pri = ["192.168.0.0/16", "172.16.0.0/12"]
      }
      tags = {
        Environment = "test"
        Purpose     = "core-network-attachment"
      }
    }
  }

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

  # Core network attachment assertions
  assert {
    condition     = length(aws_networkmanager_vpc_attachment.this) == 1
    error_message = "Should create 1 core network attachment when core_network_attach is configured"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].core_network_id == "core-network-0123456789abcdef0"
    error_message = "Core network attachment should reference the correct core network ID"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].vpc_arn == aws_vpc.this.arn
    error_message = "Core network attachment should reference the VPC ARN"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].routing_policy_label == "test-routing-policy"
    error_message = "Core network attachment routing policy label should be 'test-routing-policy'"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].appliance_mode_support == false
    error_message = "Core network attachment should have appliance mode support disabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].dns_support == true
    error_message = "Core network attachment should have DNS support enabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].security_group_referencing_support == true
    error_message = "Core network attachment should have security group referencing support enabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].options[0].ipv6_support == false
    error_message = "Core network attachment should have IPv6 support disabled"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Name == "test-cna"
    error_message = "Core network attachment name tag should follow naming convention"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Environment == "test"
    error_message = "Core network attachment should include custom tags"
  }

  assert {
    condition     = aws_networkmanager_vpc_attachment.this[0].tags.Purpose == "core-network-attachment"
    error_message = "Core network attachment should include custom tags"
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

  # Custom routes assertions (core network routes)
  assert {
    condition     = length(aws_route.cwn) > 0
    error_message = "Should create custom routes for core network traffic"
  }

  # Verify routes point to core network for private subnets
  assert {
    condition = alltrue([
      for route in aws_route.cwn : route.core_network_arn != null ? route.core_network_arn == "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0" : true
    ])
    error_message = "Core network routes should point to the correct core network ARN"
  }

  # Verify specific route destinations
  assert {
    condition = anytrue([
      for route in aws_route.cwn : route.destination_cidr_block == "192.168.0.0/16"
    ])
    error_message = "Should create route for 192.168.0.0/16 to core network"
  }

  assert {
    condition = anytrue([
      for route in aws_route.cwn : route.destination_cidr_block == "172.16.0.0/12"
    ])
    error_message = "Should create route for 172.16.0.0/12 to core network"
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

  # Verify no transit gateway attachment
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0
    error_message = "Should not create transit gateway attachment when transit_gateway_attach is null"
  }
}
