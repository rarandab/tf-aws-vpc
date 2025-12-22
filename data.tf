locals {
  az_count       = length(var.availability_zone_ids)
  subnet_newbits = ceil(log(local.az_count, 2))
  private_subnets = flatten([
    for s_k, s in var.subnet_layers : [
      for i, az in data.aws_availability_zone.this : {
        name                 = format("%s-%s", s_k, az.name_suffix)
        layer                = s_k
        cidr_block           = length(s.cidr_blocks) > 0 ? s.cidr_blocks[i] : cidrsubnet(s.cidr_block, local.subnet_newbits, i)
        availability_zone_id = az.zone_id
        az_suffix            = az.name_suffix
      }
    ] if(!s.is_public && !s.is_netatt)
  ])
  public_subnets = flatten([
    for s_k, s in var.subnet_layers : [
      for i, az in data.aws_availability_zone.this : {
        name                 = format("%s-%s", s_k, az.name_suffix)
        layer                = s_k
        cidr_block           = length(s.cidr_blocks) > 0 ? s.cidr_blocks[i] : cidrsubnet(s.cidr_block, local.subnet_newbits, i)
        availability_zone_id = az.zone_id
        az_suffix            = az.name_suffix
      }
    ] if s.is_public
  ])
  netatt_subnets = flatten([
    for s_k, s in var.subnet_layers : [
      for i, az in data.aws_availability_zone.this : {
        name                 = format("%s-%s", s_k, az.name_suffix)
        layer                = s_k
        cidr_block           = length(s.cidr_blocks) > 0 ? s.cidr_blocks[i] : cidrsubnet(s.cidr_block, local.subnet_newbits, i)
        availability_zone_id = az.zone_id
        az_suffix            = az.name_suffix
      }
    ] if s.is_netatt
  ])
  has_igw = var.nat_gateway != null || length(local.public_subnets) > 0
  route_tables = merge(
    aws_route_table.private,
    aws_route_table.public,
    aws_route_table.netatt
  )
  routes_ngw_flatten = flatten([
    for rs_k, rs in try(var.nat_gateway.routes, {}) : [
      for r in rs : [
        for az_i, az in data.aws_availability_zone.this : {
          key                        = "${rs_k}-${r}"
          route_table_k              = "${rs_k}-${az.name_suffix}"
          layer                      = rs_k
          az_suffix                  = az.name_suffix
          destination_cidr_block     = can(cidrhost(r, 0)) ? r : null
          destination_prefix_list_id = can(regex("^pl-[0-9a-f]{17}$", r)) ? r : null
          nat_gateway_id             = var.nat_gateway.mode == "regional" ? aws_nat_gateway.regional[0].id : aws_nat_gateway.zonal[az.name_suffix].id
        }
      ]
    ]
  ])
  routes_cwn_flatten = flatten([
    for rs_k, rs in try(var.core_network_attach.routes, {}) : [
      for r in rs : [
        for az_i, az in data.aws_availability_zone.this : {
          key                        = "${rs_k}-${r}"
          route_table_k              = "${rs_k}-${az.name_suffix}"
          layer                      = rs_k
          az_suffix                  = az.name_suffix
          destination_cidr_block     = can(cidrhost(r, 0)) ? r : null
          destination_prefix_list_id = can(regex("^pl-[0-9a-f]{17}$", r)) ? r : null
          core_network_arn           = var.core_network_attach.arn
        }
      ]
    ]
  ])
  routes_tgw_flatten = flatten([
    for rs_k, rs in try(var.transit_gateway_attach.routes, {}) : [
      for r in rs : [
        for az_i, az in data.aws_availability_zone.this : {
          key                        = "${rs_k}-${r}"
          route_table_k              = "${rs_k}-${az.name_suffix}"
          layer                      = rs_k
          az_suffix                  = az.name_suffix
          destination_cidr_block     = can(cidrhost(r, 0)) ? r : null
          destination_prefix_list_id = can(regex("^pl-[0-9a-f]{17}$", r)) ? r : null
          transit_gateway_id         = var.transit_gateway_attach.id
        }
      ]
    ]
  ])
  routes = merge(
    { for r in local.routes_ngw_flatten : "${r.key}-${r.az_suffix}" => r },
    { for r in local.routes_tgw_flatten : "${r.key}-${r.az_suffix}" => r },
    { for r in local.routes_cwn_flatten : "${r.key}-${r.az_suffix}" => r }
  )
}

data "aws_availability_zone" "this" {
  count = length(var.availability_zone_ids)

  region  = var.region
  zone_id = var.availability_zone_ids[count.index]
}

data "aws_caller_identity" "current" {}
