---
title: "App Template"
description: "A companion Helm chart for the common library that can deploy any application"
sidebar:
  label: "App Template"
---

## Background

Since Helm [library charts](https://helm.sh/docs/topics/library_charts/) cannot be
installed directly I have created a companion chart for the [common library](../../reference/).

## Usage

This Helm chart can be used to deploy any application. Knowing the specifics of the application you want to deploy
like the image, ports, env vars, args, and/or any config volumes will be required. You can also use [Kubesearch](https://kubesearch.dev/)
to search for applications people have deployed with this Helm chart.

In order to use this template chart, you would deploy it as you would any other Helm chart.
By setting the desired values, the common library chart will render the desired resources.

Be sure to check out the [common library docs](../../reference/)
and its [`values.yaml`](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/library/common/values.yaml) for
more information about the available configuration options.

#### Examples

This is an example `values.yaml` file that would deploy the [vaultwarden](https://github.com/dani-garcia/vaultwarden)
application. For more deployment examples, check out the [`examples` folder](https://github.com/bjw-s-labs/helm-charts/tree/main/examples/).

```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/app-template-4.6.2/charts/other/app-template/values.schema.json

controllers:
  main:
    strategy: Recreate

    containers:
      main:
        image:
          # -- image repository
          repository: vaultwarden/server
          # -- image tag
          # this example is not automatically updated, so be sure to use the latest image
          tag: 1.25.2
          # -- image pull policy
          pullPolicy: IfNotPresent

        # -- environment variables.
        # See [image docs](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template) for more details.
        env:
          # -- Config dir
          DATA_FOLDER: "config"

# -- Configures service settings for the chart.
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
  # -- Enable and configure ingress settings for the chart under this key.
  main:
    hosts:
      - host: chart-example.local
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
          - path: /notifications/hub/negotiate
            pathType: Prefix
            service:
              identifier: main
              port: http
          - path: /notifications/hub
            pathType: Prefix
            service:
              identifier: main
              port: websocket

route:
  # -- Enable and configure route settings for the chart under this key.
  main:
    parentRefs:
      - name: gateway
        namespace: gateway-namespace
        sectionName: gateway-section
    hostnames:
      - chart-example.local
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        backendRefs:
          - kind: Service
            port: 80
            name: main
            namespace: default
            weight: 1
      - matches:
          - path:
              type: PathPrefix
              value: /notifications/hub/negotiate
        backendRefs:
          - kind: Service
            port: 80
            name: main
            namespace: default
            weight: 1
      - matches:
          - path:
              type: PathPrefix
              value: /notifications/hub
        backendRefs:
          - kind: Service
            port: 3012
            name: main
            namespace: default
            weight: 1

# -- Configure persistence settings for the chart under this key.
persistence:
  config:
    type: persistentVolumeClaim
    accessMode: ReadWriteOnce
    size: 1Gi
    globalMounts:
      - path: /config
```

## Upgrade instructions

Upgrade instructions for major versions can be found [here](./upgrade-instructions/).

## Source code

The source code for the app template chart can be found
[here](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template).
