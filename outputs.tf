output "vpc" {
  description = "VPC attributes"
  value       = aws_vpc.this
}

output "subnets" {
  description = "Subnets attributes"
  value = {
    public  = aws_subnet.public
    private = aws_subnet.private
    netatt  = aws_subnet.netatt
  }
}

output "route_tables" {
  description = "Route tables attributes"
  value = {
    public  = aws_route_table.public
    private = aws_route_table.private
    netatt  = aws_route_table.netatt
  }
}

output "network_acls" {
  description = "Network ACLs attributes"
  value = {
    public  = aws_network_acl.public
    private = aws_network_acl.private
    netatt  = aws_network_acl.netatt
  }
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

