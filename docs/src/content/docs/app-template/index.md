---
title: "App Template"
description: "A Helm chart to deploy any application using the common library"
---

App Template is a companion Helm chart that works alongside the **Common Library** to deploy any application in Kubernetes. Since Helm [library charts](https://helm.sh/docs/topics/library_charts/) cannot be installed directly, App Template provides a ready-to-use wrapper that leverages the Common Library's powerful resource rendering capabilities.

## How it works

The App Template chart accepts standard Kubernetes resource definitions in its `values.yaml` and passes them to the Common Library for processing. The Common Library then renders the appropriate Kubernetes manifests (Deployments, Services, ConfigMaps, etc.) based on your configuration.

This separation means:

- **App Template** handles deployment structure and user-facing configuration
- **Common Library** handles the complex logic of rendering Kubernetes resources

## Quick example

Here is an example `values.yaml` file that deploys [vaultwarden](https://github.com/dani-garcia/vaultwarden):

```yaml
controllers:
  main:
    strategy: Recreate

    containers:
      main:
        image:
          repository: vaultwarden/server
          tag: 1.25.2

        env:
          DATA_FOLDER: "config"

service:
  main:
    controller: main
    ports:
      http:
        port: 80
      websocket:
        enabled: true
        port: 3012

ingress:
  main:
    hosts:
      - host: vaultwarden.example.com
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http

persistence:
  config:
    type: persistentVolumeClaim
    accessMode: ReadWriteOnce
    size: 1Gi
    globalMounts:
      - path: /config
```

## Next steps

- [Get started](./getting-started.md) with deploying your first application
- Browse the [How-to guides](./howto/) for common configuration patterns
- Explore [Examples](./examples/) for complex deployments
- View the [Values Reference](./reference/) for all available options

## Source code

The source code for both charts can be found here:

- [App Template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template)
- [Common Library](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/library/common)
