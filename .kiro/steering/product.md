---
inclusion: always
---

# AWS VPC Terraform Module

## Purpose
This Terraform module provisions a single AWS VPC with DNS configuration and DHCP options. It creates foundational networking infrastructure that can be extended with subnets, gateways, and other networking components.

## Core Functionality
- **VPC Creation**: Provisions a single VPC with configurable CIDR block
- **DNS Configuration**: Enables DNS hostnames and support by default for proper name resolution
- **DHCP Options**: Associates Amazon-provided DNS servers with the VPC
- **Consistent Naming**: Uses name prefix pattern for all resources

## Key Design Principles
- **Simplicity**: Focused on core VPC provisioning without complex subnet management
- **Extensibility**: Designed to be a foundation that can be extended with additional networking resources
- **AWS Best Practices**: Follows AWS networking conventions with proper DNS configuration
- **Validation**: Input validation ensures CIDR blocks and regions are properly formatted

## Usage Context
This module is intended for scenarios where you need a basic VPC foundation. It does not include subnets, route tables, or gateways - those should be added separately or through other modules depending on your architecture needs.

## Configuration Options
- Configurable DNS settings (hostnames and support)
- CIDR block validation
- AWS region specification with format validation
- Consistent resource naming via name prefix