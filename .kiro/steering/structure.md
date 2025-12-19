---
inclusion: always
---

# Terraform Module Structure Guidelines

## Required Files
- **variables.tf**: Define all input parameters with descriptions, types, and validation blocks
- **outputs.tf**: Define all output values with descriptions for module consumers
- **main.tf**: Contains primary resource definitions and module logic
- **versions.tf**: Specify Terraform and provider version constraints
- **data.tf**: Define the terraform data and local variables of the module
- **README.md**: Auto-generated documentation using terraform-docs

## Optional Directories
- **examples/**: Working examples demonstrating module usage patterns
- **tests/**: Automated tests for module validation

## File Organization Rules
- Keep related resources grouped logically in main.tf
- Use consistent variable ordering: required first, then optional with defaults
- Output all meaningful resource attributes that consumers might need
- Include data sources in main.tf unless they warrant separate files for complex modules

## Naming Conventions
- Use snake_case for all Terraform identifiers (variables, outputs, resources)
- Prefix resource names with descriptive identifiers
- Group related variables using object types when appropriate

## Documentation Requirements
- All variables must have meaningful descriptions
- All outputs must have descriptions explaining their purpose
- Use terraform-docs configuration in .terraform-docs.yml for consistent formatting