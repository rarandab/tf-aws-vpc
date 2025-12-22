variable "name_prefix" {
  description = "Name prefix for the resources"
  type        = string
}

variable "region" {
  type        = string
  description = "AWS region for all resources"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "The region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "availability_zone_ids" {
  description = "List of availability zone IDs"
  type        = list(string)
  validation {
    condition = length(var.availability_zone_ids) > 0 && alltrue([
      for az_id in var.availability_zone_ids : can(regex("^[a-z]{3}[0-9]{1}-az[0-9]+$", az_id))
    ])
    error_message = "The availability_zone_ids variable must have at least one component and each component must be a valid AZ ID format (e.g., use1-az1, use1-az2)."
  }
}

variable "cidr_blocks" {
  description = "VPC CIDRs"
  type        = list(string)
  validation {
    condition = length(var.cidr_blocks) > 0 && alltrue([
      for cidr in var.cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "The cidr_blocks variable must have at least one component and each component must be a valid CIDR block."
  }
}

variable "config" {
  description = "A configuration object for the VPC."
  type = object({
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
  })
  default = {}
}

variable "dhcp_options" {
  type = object({
    domain_name          = optional(string, null)
    domain_name_servers  = optional(list(string), ["AmazonProvidedDNS"])
    ntp_servers          = optional(list(string))
    netbios_name_servers = optional(list(string))
    netbios_node_type    = optional(number)
  })
  default     = {}
  description = "DHCP options parameters for the VPC"
}

variable "subnet_layers" {
  description = "List of subnet layer configurations"
  type = map(object({
    cidr_block  = optional(string)
    cidr_blocks = optional(list(string), [])
    is_public   = optional(bool, false)
    is_netatt   = optional(bool, false)
    tags        = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for layer_key, layer in var.subnet_layers : !(layer.is_public == true && layer.is_netatt == true)
    ])
    error_message = "A subnet layer cannot have both is_public and is_netatt set to true."
  }
  validation {
    condition = alltrue([
      for layer_key, layer in var.subnet_layers : !(layer.cidr_block != null && length(layer.cidr_blocks) > 0)
    ])
    error_message = "A subnet layer cannot have both cidr_block and cidr_blocks configured at the same time."
  }
  validation {
    condition = length([
      for layer_key, layer in var.subnet_layers : layer_key if layer.is_netatt == true
    ]) <= 1
    error_message = "Only one subnet layer can have is_netatt set to true."
  }
}

variable "route_table_per_az" {
  description = "Create a route table per availability zone"
  type        = bool
  default     = false
}

variable "nat_gateway" {
  description = "NAT Gateway configuration"
  type = object({
    mode         = optional(string, "regional")
    subnet_layer = optional(string)
    routes       = optional(map(list(string)), {})
  })
  default = null
  validation {
    condition     = var.nat_gateway == null || contains(["regional", "zonal"], var.nat_gateway.mode)
    error_message = "The nat_gateway mode must be either 'regional' or 'zonal'."
  }
  validation {
    condition     = var.nat_gateway == null || var.nat_gateway.mode != "zonal" || (var.nat_gateway.subnet_layer != null && var.nat_gateway.subnet_layer != "")
    error_message = "When nat_gateway mode is 'zonal', subnet_layer must be a non-empty string."
  }
  validation {
    condition = var.nat_gateway == null || var.nat_gateway.routes == null || alltrue([
      for rs_k, rs in var.nat_gateway.routes : alltrue([
        for r in rs : can(cidrhost(r, 0)) || can(regex("^pl-[0-9a-f]{17}$", r))
      ])
    ])
    error_message = "In nat_gateway routes, values must be a list of either valid CIDR blocks or valid prefix list IDs (format: pl-<17-hex-chars>)."
  }
}

variable "core_network_attach" {
  description = "Core network parameters for the VPC"
  type = object({
    id                                 = string
    arn                                = string
    tags                               = optional(map(string), {})
    routing_policy_label               = optional(string)
    appliance_mode_support             = optional(bool, false)
    dns_support                        = optional(bool, false)
    security_group_referencing_support = optional(bool, false)
    routes                             = optional(map(list(string)), {})
  })
  default = null
  validation {
    condition     = var.core_network_attach == null || can(regex("^core-network-[0-9a-f]{17}$", var.core_network_attach.id))
    error_message = "The core_network_attach id must be in the format 'core-network-' followed by 17 hexadecimal characters."
  }
  validation {
    condition     = var.core_network_attach == null || can(regex("^arn:aws:networkmanager::[0-9]{12}:core-network/core-network-[0-9a-f]{17}$", var.core_network_attach.arn))
    error_message = "The core_network_attach arn must be in the format 'arn:aws:networkmanager::<account-id>:core-network/core-network-<17-hex-chars>'."
  }
  validation {
    condition = var.core_network_attach == null || var.core_network_attach.routes == null || alltrue([
      for rs_k, rs in var.core_network_attach.routes : alltrue([
        for r in rs : can(cidrhost(r, 0)) || can(regex("^pl-[0-9a-f]{17}$", r))
      ])
    ])
    error_message = "In core_network_attach routes, values must be a list of either valid CIDR blocks or valid prefix list IDs (format: pl-<17-hex-chars>)."
  }
}

variable "transit_gateway_attach" {
  description = "values for the transit gateway attachment"
  type = object({
    id                                 = string
    appliance_mode_support             = optional(bool, false)
    dns_support                        = optional(bool, false)
    security_group_referencing_support = optional(bool, false)
    routes                             = optional(map(list(string)), {})
  })
  default = null
  validation {
    condition     = var.transit_gateway_attach == null || can(regex("^tgw-[0-9a-f]{17}$", var.transit_gateway_attach.id))
    error_message = "The transit_gateway_attach id must be in the format 'tgw-' followed by 17 hexadecimal characters."
  }
  validation {
    condition = var.transit_gateway_attach == null || var.transit_gateway_attach.routes == null || alltrue([
      for rs_k, rs in var.transit_gateway_attach.routes : alltrue([
        for r in rs : can(cidrhost(r, 0)) || can(regex("^pl-[0-9a-f]{17}$", r))
      ])
    ])
    error_message = "In transit_gateway_attach routes, values must be a list of either valid CIDR blocks or valid prefix list IDs (format: pl-<17-hex-chars>)."
  }
}

variable "flow_logs" {
  description = "Flow Logs configuration"
  type = object({
    retention_in_days = optional(number, 30)
    iam_role_arn      = optional(string)
    kms_key_arn       = optional(string)
    log_format        = optional(string)
    tags              = optional(map(string), {})
  })
  default = null
}
