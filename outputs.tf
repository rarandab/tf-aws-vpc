output "vpc" {
  description = "VPC attributes"
  value       = aws_vpc.this
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = data.aws_availability_zone.this[*]
}

output "subnets" {
  description = "Subnets attributes"
  value = merge(
    aws_subnet.public,
    aws_subnet.private,
    aws_subnet.netatt
  )
}

output "route_tables" {
  description = "Route tables attributes"
  value = merge(
    aws_route_table.public,
    aws_route_table.private,
    aws_route_table.netatt
  )
}

output "network_acls" {
  description = "Network ACLs attributes"
  value = merge(
    aws_network_acl.public,
    aws_network_acl.private,
    aws_network_acl.netatt
  )
}

output "core_network_attachment" {
  description = "Core network attachment attributes"
  value       = one(aws_networkmanager_vpc_attachment.this[*])
}

output "transit_gateway_attachment" {
  description = "Transit gateway attachment attributes"
  value       = one(aws_ec2_transit_gateway_vpc_attachment.this[*])
}

output "flowlogs_cwlg" {
  description = "Cloudwatch LogGroup for VPC Flow Logs"
  value       = one(aws_cloudwatch_log_group.flow_logs[*])
}

