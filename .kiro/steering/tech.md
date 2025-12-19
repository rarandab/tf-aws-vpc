---
inclusion: always
---

# Terraform AWS Module Guidelines

## Technology Stack
- **Terraform**: Infrastructure as Code using Terraform >= 1.0
- **AWS Provider**: Use hashicorp/aws provider >= 6.0
- **GitHub Actions**: Automated CI/CD for validation and documentation

## Code Standards

### Terraform Conventions
- Use `terraform fmt` for consistent formatting
- All resources must include meaningful tags with `Name` attribute
- Use `format()` function for consistent naming: `format("%s-resource-type", var.name_prefix)`
- Implement input validation using `validation` blocks where appropriate
- Use `optional()` for object attributes with sensible defaults

### Variable Patterns
- Always include `name_prefix` variable for resource naming consistency
- Use `region` variable with validation for AWS region format
- Group related configuration in objects (e.g., `config` object for feature flags)
- Validate CIDR blocks using `can(cidrhost(cidr, 0))` pattern

### Documentation
- Use terraform-docs with `.terraform-docs.yml` configuration
- Auto-generate README.md documentation via GitHub Actions
- Include provider requirements, inputs, outputs, and resources sections

### CI/CD Requirements
- All code must pass `terraform fmt -check`
- All code must pass `terraform validate`
- Documentation updates are automated via GitHub Actions
- PR comments show validation results automatically

## Architecture Patterns
- Follow AWS Well-Architected Framework principles
- Use descriptive resource names with consistent prefixes
- Enable DNS hostnames and support by default for VPC resources
- Associate DHCP options with VPCs for proper DNS resolution