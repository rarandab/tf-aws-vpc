# VPC resources
resource "aws_vpc" "this" {
  region               = var.region
  cidr_block           = var.cidr_blocks[0]
  enable_dns_hostnames = var.config.enable_dns_hostnames
  enable_dns_support   = var.config.enable_dns_support

  tags = {
    Name = format("%s-vpc", var.name_prefix)
  }
}

resource "aws_vpc_dhcp_options" "this" {
  region               = var.region
  domain_name          = var.dhcp_options.domain_name
  domain_name_servers  = var.dhcp_options.domain_name_servers
  ntp_servers          = var.dhcp_options.ntp_servers
  netbios_name_servers = var.dhcp_options.netbios_name_servers
  netbios_node_type    = var.dhcp_options.netbios_node_type

  tags = {
    Name = format("%s-dop", var.name_prefix)
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  region          = var.region
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}

resource "aws_internet_gateway" "this" {
  count  = local.has_igw ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-igw", var.name_prefix)
  }
}

# Subnets
resource "aws_subnet" "private" {
  for_each = { for s in local.private_subnets : s.key => s }

  region               = var.region
  vpc_id               = aws_vpc.this.id
  cidr_block           = each.value.cidr_block
  availability_zone_id = each.value.availability_zone_id

  tags = {
    Name = format("%s-snt-%s", var.name_prefix, each.value.name)
  }
}

resource "aws_subnet" "public" {
  for_each = { for s in local.public_subnets : s.key => s }

  region                  = var.region
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone_id    = each.value.availability_zone_id
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-snt-%s", var.name_prefix, each.value.name)
  }
}

resource "aws_subnet" "netatt" {
  for_each = { for s in local.netatt_subnets : s.key => s }

  region               = var.region
  vpc_id               = aws_vpc.this.id
  cidr_block           = each.value.cidr_block
  availability_zone_id = each.value.availability_zone_id

  tags = {
    Name = format("%s-snt-%s", var.name_prefix, each.value.name)
  }
}

# Route tables
resource "aws_route_table" "private" {
  for_each = { for s in local.private_subnets : s.key => s }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-rtb-%s", var.name_prefix, each.value.name)
  }
}
resource "aws_route_table_association" "private" {
  for_each = { for s in local.private_subnets : s.key => s }

  region         = var.region
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "public" {
  for_each = { for s in local.public_subnets : s.key => s }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-rtb-%s", var.name_prefix, each.value.name)
  }
}
resource "aws_route_table_association" "public" {
  for_each = { for s in local.public_subnets : s.key => s }

  region         = var.region
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table" "netatt" {
  for_each = { for s in local.netatt_subnets : s.key => s }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-rtb-%s", var.name_prefix, each.value.name)
  }
}
resource "aws_route_table_association" "netatt" {
  for_each = { for s in local.netatt_subnets : s.key => s }

  region         = var.region
  subnet_id      = aws_subnet.netatt[each.key].id
  route_table_id = aws_route_table.netatt[each.key].id
}

# Network ACLs
resource "aws_network_acl" "private" {
  for_each = { for s_k, s in var.subnet_layers : s_k => s if(!s.is_public && !s.is_netatt) }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-acl-%s", var.name_prefix, each.key)
  }
}
resource "aws_network_acl_association" "private" {
  for_each = { for s in local.private_subnets : s.key => s }

  region         = var.region
  network_acl_id = aws_network_acl.private[each.value.layer].id
  subnet_id      = aws_subnet.private[each.key].id
}

resource "aws_network_acl" "public" {
  for_each = { for s_k, s in var.subnet_layers : s_k => s if(s.is_public) }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-acl-%s", var.name_prefix, each.key)
  }
}
resource "aws_network_acl_association" "public" {
  for_each = { for s in local.public_subnets : s.key => s }

  region         = var.region
  network_acl_id = aws_network_acl.public[each.value.layer].id
  subnet_id      = aws_subnet.public[each.key].id
}

resource "aws_network_acl" "netatt" {
  for_each = { for s_k, s in var.subnet_layers : s_k => s if(s.is_netatt) }

  region = var.region
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-acl-%s", var.name_prefix, each.key)
  }
}
resource "aws_network_acl_association" "netatt" {
  for_each = { for s in local.netatt_subnets : s.key => s }

  region         = var.region
  network_acl_id = aws_network_acl.netatt[each.value.layer].id
  subnet_id      = aws_subnet.netatt[each.key].id
}

# NAT Gateway
resource "aws_nat_gateway" "regional" {
  count = var.nat_gateway != null && var.nat_gateway.mode == "regional" ? 1 : 0

  region            = var.region
  availability_mode = "regional"

  tags = {
    Name = format("%s-ngw", var.name_prefix)
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "ngw" {
  for_each = var.nat_gateway != null && var.nat_gateway.mode == "zonal" ? { for s in local.public_subnets : s.az_suffix => s if s.layer == var.nat_gateway.subnet_layer } : {}

  region = var.region

  tags = {
    Name = format("%s-eip-ngw-%s", var.name_prefix, each.value.az_suffix)
  }
}

resource "aws_nat_gateway" "zonal" {
  for_each = var.nat_gateway != null && var.nat_gateway.mode == "zonal" ? { for s in local.public_subnets : s.az_suffix => s if s.layer == var.nat_gateway.subnet_layer } : {}

  region            = var.region
  allocation_id     = aws_eip.ngw[each.key].id
  connectivity_type = "public"
  subnet_id         = aws_subnet.public[each.value.key].id

  tags = {
    Name = format("%s-ngw-%s", var.name_prefix, each.value.az_suffix)
  }

  depends_on = [aws_internet_gateway.this]
}

# Core Network attachment
resource "aws_networkmanager_vpc_attachment" "this" {
  count = var.core_network_attach != null ? 1 : 0

  subnet_arns          = [for k, v in aws_subnet.netatt : v.arn]
  core_network_id      = var.core_network_attach.id
  vpc_arn              = aws_vpc.this.arn
  routing_policy_label = var.core_network_attach.routing_policy_label
  options {
    appliance_mode_support             = var.core_network_attach.appliance_mode_support
    dns_support                        = var.core_network_attach.dns_support
    security_group_referencing_support = var.core_network_attach.security_group_referencing_support
    ipv6_support                       = false
  }

  tags = merge(
    var.core_network_attach.tags,
    {
      Name = format("%s-cna", var.name_prefix)
    }
  )
}

# Transit Gateway attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.transit_gateway_attach != null ? 1 : 0

  region                             = var.region
  subnet_ids                         = [for k, v in aws_subnet.netatt : v.id]
  transit_gateway_id                 = var.transit_gateway_attach.id
  vpc_id                             = aws_vpc.this.id
  appliance_mode_support             = var.transit_gateway_attach.appliance_mode_support ? "enable" : "disable"
  dns_support                        = var.transit_gateway_attach.dns_support ? "enable" : "disable"
  security_group_referencing_support = var.transit_gateway_attach.security_group_referencing_support ? "enable" : "disable"
  ipv6_support                       = "disable"

  tags = {
    Name = format("%s-tga", var.name_prefix)
  }
}

# Routes
//resource "aws_route" "custom" {
//  for_each = local.routes
//
//  region                     = var.region
//  route_table_id             = local.route_tables[each.value.route_table_k].id
//  destination_cidr_block     = each.value.destination_cidr_block
//  destination_prefix_list_id = each.value.destination_prefix_list_id
//  nat_gateway_id             = try(each.value.nat_gateway_id, null)
//  transit_gateway_id         = try(each.value.transit_gateway_id, null)
//  core_network_arn           = try(each.value.core_network_arn, null)
//
//  depends_on = [
//    aws_nat_gateway.regional,
//    aws_nat_gateway.zonal,
//    aws_ec2_transit_gateway_vpc_attachment.this,
//    aws_networkmanager_vpc_attachment.this
//  ]
//}

resource "aws_route" "ngw" {
  for_each = { for r in local.routes_ngw_flatten : "${r.key}/${r.az_suffix}" => r }

  region                     = var.region
  route_table_id             = local.route_tables[each.value.route_table_k].id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  nat_gateway_id             = each.value.nat_gateway_id

  depends_on = [
    aws_nat_gateway.regional,
    aws_nat_gateway.zonal
  ]
}

resource "aws_route" "tgw" {
  for_each = { for r in local.routes_tgw_flatten : "${r.key}/${r.az_suffix}" => r }

  region                     = var.region
  route_table_id             = local.route_tables[each.value.route_table_k].id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  transit_gateway_id         = each.value.transit_gateway_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this
  ]
}

resource "aws_route" "cwn" {
  for_each = { for r in local.routes_cwn_flatten : "${r.key}/${r.az_suffix}" => r }

  region                     = var.region
  route_table_id             = local.route_tables[each.value.route_table_k].id
  destination_cidr_block     = each.value.destination_cidr_block
  destination_prefix_list_id = each.value.destination_prefix_list_id
  core_network_arn           = each.value.core_network_arn

  depends_on = [
    aws_networkmanager_vpc_attachment.this
  ]
}

# FlowLogs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.flow_logs != null ? 1 : 0

  region            = var.region
  name              = format("/flowlogs/%s-vpc", var.name_prefix)
  retention_in_days = var.flow_logs.retention_in_days
  kms_key_id        = var.flow_logs.kms_key_arn
  tags = merge(
    var.flow_logs.tags,
    {
      Name = format("%s-flowlogs", var.name_prefix)
    }
  )
}

data "aws_iam_policy_document" "trust_flow_logs" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.flow_logs != null && var.flow_logs.iam_role_arn == null ? 1 : 0

  path               = format("/%s/", var.name_prefix)
  name               = format("%s-irl-flowlogs", var.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.trust_flow_logs.json
  tags = {
    Name = format("%s-irl-flowlogs", var.name_prefix)
  }
}

data "aws_iam_policy_document" "permissions_cw_flow_logs" {
  count = length(aws_iam_role.flow_logs) == 1 ? 1 : 0

  statement {
    sid    = "ListLogGroups"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ListLogStreams"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
    ]
    resources = [one(aws_cloudwatch_log_group.flow_logs[*].arn)]
  }
  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [format("%s:log-stream:*", one(aws_cloudwatch_log_group.flow_logs[*].arn))]
  }
}

resource "aws_iam_role_policy" "permissions_cw_flow_logs" {
  count = length(aws_iam_role.flow_logs) == 1 ? 1 : 0

  name   = "flowlogs"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.permissions_cw_flow_logs[0].json
}

data "aws_iam_policy_document" "permissions_kms_flog_logs" {
  count = length(aws_iam_role.flow_logs) == 1 && var.flow_logs.kms_key_arn != null ? 1 : 0

  statement {
    sid    = "UseKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Descrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [var.flow_logs.kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [format("logs.%s.amazonaws.com", var.region)]
    }
  }
}

resource "aws_iam_role_policy" "permissions_kms_flog_logs" {
  count = length(aws_iam_role.flow_logs) == 1 && var.flow_logs.kms_key_arn != null ? 1 : 0

  name   = "kms"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.permissions_kms_flog_logs[0].json
}

resource "aws_flow_log" "this" {
  count = var.flow_logs != null ? 1 : 0

  iam_role_arn         = var.flow_logs.iam_role_arn != null ? var.flow_logs.iam_role_arn : aws_iam_role.flow_logs[0].arn
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}
