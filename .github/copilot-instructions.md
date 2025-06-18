# GitHub Copilot Instructions for helm-charts

## Instruction Files Reference

When helping with this repository, use these instruction files for specific guidance:

- [Project Purpose and Goals](.github/instructions/project-purpose.instructions.md) - Use to understand the core purpose and design philosophy of the repository
- [Common Library Development](.github/instructions/common-library.instructions.md) - Use when modifying or extending the common library chart
- [Chart Testing](.github/instructions/chart-testing.instructions.md) - Use when testing charts or adding new tests
- [Documentation](.github/instructions/documentation.instructions.md) - Use when updating or creating documentation
- [Examples](.github/instructions/examples.instructions.md) - Use when working with example configurations
- [Version Management](.github/instructions/versioning.instructions.md) - Use when updating chart versions

## Overview

This repository contains a collection of Helm charts used for deploying applications in Kubernetes clusters. The primary components are:

1. A `common` library chart that provides reusable Helm templates and functions
2. An `app-template` chart that leverages the common library for easy application deployment

## Repository Structure

- `charts/`: Contains the Helm charts
  - `library/common/`: The common library chart with reusable templates and functions
  - `other/app-template/`: A generic application template chart for deploying various applications
- `docs/`: Documentation for the charts
- `examples/`: Example configurations for using the charts with different tools (Helm, Flux, Kustomize)

## Common Tasks

When working with this repository, you'll typically need to:

1. Understand the chart structure and how components relate to each other
2. Create or modify Helm templates
3. Update chart versions following semantic versioning
4. Update Chart.yaml annotations with changelog entries
5. Test chart changes

## Development Guidelines

- Chart versions must follow [semver](https://semver.org/) principles
- Any change to a chart requires a version bump
- Chart releases must be immutable
- Follow the [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/)
- Sign off all commits with `git commit -s`

## Tools and Commands

This repository uses [Task](https://taskfile.dev/) for automation. The main task commands include:

- `task charts:lint`: Lint all charts
- `task charts:test`: Test charts
- `task docs:serve`: Serve the documentation locally
