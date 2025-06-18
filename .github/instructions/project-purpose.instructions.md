# Project Purpose and Goals

This document outlines the core purpose, design philosophy, and goals of the helm-charts repository.

## Core Purpose

The helm-charts repository provides a standardized approach to Kubernetes application deployment through a reusable library chart pattern. It follows the DRY (Don't Repeat Yourself) principle for Helm charting, recognizing that many applications require similar Kubernetes resources with only slight variations.

## Design Philosophy

The repository is built around these key principles:

### 1. Abstraction through Library Charts

Helm's [library charts](https://helm.sh/docs/topics/library_charts/) allow for sharing chart primitives across multiple charts. This repository leverages this concept by:

- Centralizing common templates and functions in a single library chart
- Providing consistent interfaces for resource generation
- Exposing a simplified API for application deployment

### 2. Configuration over Code

Rather than requiring users to write custom templates for each application, this repository:

- Provides a declarative configuration approach
- Uses values.yaml for defining application requirements
- Generates appropriate Kubernetes resources based on configuration

### 3. Convention over Configuration

The charts implement sensible defaults while allowing for customization:

- Standard resource naming conventions
- Common label patterns
- Predictable resource relationships
- Escape hatches for advanced scenarios

## Repository Goals

The helm-charts repository aims to:

### 1. Standardization

Create a consistent approach to defining Kubernetes resources by:
- Establishing uniform resource naming
- Applying common labeling patterns
- Maintaining consistent relationship patterns between resources
- Providing standardized validation through JSON schemas

### 2. Reusability

Avoid duplicating code across multiple Helm charts by:
- Centralizing template logic in a common library
- Sharing helper functions across different resource types
- Creating reusable patterns for common deployment scenarios
- Building composable components

### 3. Simplicity

Make it easier to deploy applications to Kubernetes by:
- Reducing boilerplate configuration
- Providing intuitive defaults
- Creating a streamlined interface for common scenarios
- Minimizing the learning curve for users

### 4. Flexibility

Support a wide range of application types and deployment scenarios through:
- Extensible templates that handle various application requirements
- Support for different Kubernetes resource types
- Configurability through values files
- Escape hatches for complex use cases

### 5. Maintainability

Centralize common functionality to simplify updates and fixes by:
- Consolidating resource generation logic
- Standardizing validation
- Using shared templates for common patterns
- Implementing consistent testing approaches

## Components and Their Purpose

### Common Library Chart

The `common` library chart (`charts/library/common/`) is the foundation of the repository, providing:

- **Template Classes**: Blueprint templates for Kubernetes resources like Deployments, Services, etc.
- **Library Functions**: Helper functions that simplify resource generation
- **Value Validation**: JSON schemas that validate chart values
- **Resource Rendering**: Logic for rendering various Kubernetes resources

### App Template Chart

The `app-template` chart (`charts/other/app-template/`) is a companion chart that:

- Leverages the common library to provide a turnkey solution for application deployment
- Offers a consistent interface for deploying various applications
- Reduces the barrier to entry for deploying applications on Kubernetes
- Provides a reference implementation of the common library

## Use Cases

The helm-charts repository is designed for:

1. **Application Deployment**: Simplifying the process of deploying applications on Kubernetes
2. **GitOps Workflows**: Supporting declarative configuration for GitOps tools like Flux
3. **Standardized Operations**: Enabling consistent operational patterns across applications
4. **Learning and Reference**: Providing examples of Helm best practices and patterns

## Related Documentation

The helm-charts repository contains several types of documentation to help users and contributors understand and use the charts effectively. The documentation covers aspects such as:

- **Common Library Development**: Details on modifying or extending the common library chart
- **App Template Development**: Guidance for working with the app-template chart
- **Documentation Guidelines**: Instructions for maintaining repository documentation
- **Examples**: Information about example configurations and use cases
