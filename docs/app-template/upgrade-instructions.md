# Upgrade instructions

## From 3.x.x to 4.0.x

Migrating from v3.x to v4.x introduces a number of breaking changes. Additionally, the minimum required Kubernetes version has been increased to version **1.28.x**.

#### Resource names

A new and consistent resource naming scheme has been implemented throughout the chart.

!!! info
    See **[here](../common-library/resources/names.md)** for more information on how the new naming scheme works.

This change may lead to generated resources getting new names, causing resources with the old naming scheme to be removed.

!!! warning
    **IMPORTANT** As with any major software version upgrade, please verify that you have a working backup of your data.

#### serviceAccounts

##### Tokens

When creating a serviceAccount in v3, this would always also create a Secret containing a static long-lived Service Account token. Nowadays it is preferable to use short-lived tokens and have Kubernetes manage them automatically.

If a static long-lived token is still required for a serviceAccount, this can be configured by setting the `staticToken` key of the serviceAccount to `true`.

##### Creation

The syntax for creating service accounts has changed. Instead of configuring a `default` serviceAccount and optional `extraServiceAccounts` the syntax has been brought in line with other resources:

```yaml
serviceAccount:
  myServiceAccount: {}
  mySecondServiceAccount:
    staticToken: true
  myThirdServiceAccount:
    enabled: false

controllers:
  main:
    serviceAccount:
      identifier: myServiceAccount
```

#### Controller labels

The hardcoded `app.kubernetes.io/component` label that is used to target specific controllers has been renamed to `app.kubernetes.io/controller`.

!!! info
    Because controller labels are considered immutable by Kubernetes existing Deployments / StatefulSets / etc will have to be recreated.

## From 2.x.x to 3.0.x

The main changes from v2.x to v3.x are the removal of the default `main` objects and the introduction of JSON schema validation.

Given the following real-life example values.yaml for app-template v2:

<details>
<summary>Expand</summary>

```yaml
---
defaultPodOptions:
  securityContext:
    runAsUser: 568
    runAsGroup: 568
    fsGroup: 568
    fsGroupChangePolicy: "OnRootMismatch"
    supplementalGroups:
      - 65539

controllers:
  main:
    containers:
      main:
        image:
          repository: ghcr.io/onedr0p/sabnzbd
          tag: latest
          pullPolicy: IfNotPresent

service:
  main:
    ports:
      http:
        port: 8080

ingress:
  media:
    enabled: true
    className: "ingress-nginx"
    hosts:
      - host: sabnzbd.bjw-s.dev
        paths:
          - path: /
            service:
              name: main
              port: http

persistence:
  media:
    existingClaim: nas-media
    globalMounts:
      - path: /data/nas-media
```

</details>

The values for app-template v3.x would become this:

```yaml
---
defaultPodOptions:
  enableServiceLinks: true
  securityContext:
    runAsUser: 568
    runAsGroup: 568
    fsGroup: 568
    fsGroupChangePolicy: "OnRootMismatch"
    supplementalGroups:
      - 65539

controllers:
  sabnzbd: # this can now be any name you wish
    containers:
      app: # this can now be any name you wish
        image:
          repository: ghcr.io/onedr0p/sabnzbd
          tag: latest
          pullPolicy: IfNotPresent

        probes:
          liveness:
            enabled: true
          readiness:
            enabled: true
          startup:
            enabled: true
            spec:
              failureThreshold: 30
              periodSeconds: 5

service:
  app: # this can now be any name you wish
    controller: sabnzbd
    ports:
      http:
        port: 8080

ingress:
  media: # this can now be any name you wish
    className: "ingress-nginx"
    hosts:
      - host: sabnzbd.bjw-s.dev
        paths:
          - path: /
            service:
              identifier: app
              port: http

persistence:
  media:
    existingClaim: nas-media
    globalMounts:
      - path: /data/nas-media
```

#### 🚧 Diff view

<details>
<summary>Expand</summary>

```diff
--- old
+++ new
@@ -1,42 +1,55 @@
---
 defaultPodOptions:
+  enableServiceLinks: true
   securityContext:
     runAsUser: 568
     runAsGroup: 568
     fsGroup: 568
     fsGroupChangePolicy: "OnRootMismatch"
     supplementalGroups:
       - 65539

 controllers:
-  main:
+  sabnzbd: # this can now be any name you wish
     containers:
-      main:
+      app: # this can now be any name you wish
         image:
           repository: ghcr.io/onedr0p/sabnzbd
           tag: latest
           pullPolicy: IfNotPresent

+        probes:
+          liveness:
+            enabled: true
+          readiness:
+            enabled: true
+          startup:
+            enabled: true
+            spec:
+              failureThreshold: 30
+              periodSeconds: 5
+
 service:
-  main:
+  app: # this can now be any name you wish
+    controller: sabnzbd
     ports:
       http:
         port: 8080

 ingress:
-  media:
-    enabled: true
+  media: # this can now be any name you wish
     className: "ingress-nginx"
     hosts:
       - host: sabnzbd.bjw-s.dev
         paths:
           - path: /
             service:
-              name: main
+              identifier: app
               port: http

 persistence:
   media:
     existingClaim: nas-media
     globalMounts:
       - path: /data/nas-media

```

</details>

#### Changes in this example

This is not meant as an exhaustive list of changes, but rather a "most common" example.

- The `main` object for controllers, containers, services and ingress has been removed from `values.yaml` and will therefore no longer provide any (both expected and unexpected) default values.
- The `config` object for persistence has been removed from `values.yaml` and will therefore no longer provide any (both expected and unexpected) default values.
- `enableServiceLinks` has been disabled by default. In order to explicitly enable serviceLinks, set the value to `true`.
- `ingress.*.hosts.*.paths.*.service` Service references now require either `name` or `identifier` to be set.
- Persistence items of type `configMap` and `secret` object references now allow either `name` or `identifier` to be set.

## From 1.x.x to 2.0.x

!!! warning

    **IMPORTANT** Because a new label has been introduced in the controller labelSelector (which is an immutable field), Deployments cannot be upgraded in place!
    [More details](https://www.datree.io/resources/kubernetes-error-codes-field-is-immutable)

!!! info

    Some items (Ingress, ports, persistence items, etc) now default to being enabled by default. However, this is not always the case for some of the `items due to overrides in the default `values.yaml`.
    [More background](https://github.com/bjw-s-labs/helm-charts/issues/205)

Given the following real-life example values.yaml for app-template v1:

<details>
<summary>Expand</summary>

```yaml
image:
  repository: ghcr.io/onedr0p/sabnzbd
  tag: latest
  pullPolicy: IfNotPresent

podSecurityContext:
  runAsUser: 568
  runAsGroup: 568
  fsGroup: 568
  fsGroupChangePolicy: "OnRootMismatch"
  supplementalGroups:
    - 65539

service:
  main:
    ports:
      http:
        port: 8080

ingress:
  media:
    enabled: true
    ingressClassName: "ingress-nginx"
    hosts:
      - host: sabnzbd.bjw-s.dev
        paths:
          - path: /

persistence:
  media:
    enabled: true
    existingClaim: nas-media
    globalMounts:
      - path: /data/nas-media

probes:
  liveness:
    enabled: false
  readiness:
    enabled: false
  startup:
    enabled: false
```

</details>

The values for app-template v2.x would become this:

```yaml
defaultPodOptions:
  securityContext:
    runAsUser: 568
    runAsGroup: 568
    fsGroup: 568
    fsGroupChangePolicy: "OnRootMismatch"
    supplementalGroups:
      - 65539

controllers:
  main:
    containers:
      main:
        image:
          repository: ghcr.io/onedr0p/sabnzbd
          tag: latest
          pullPolicy: IfNotPresent

        probes:
          liveness:
            enabled: false
          readiness:
            enabled: false
          startup:
            enabled: false

service:
  main:
    ports:
      http:
        port: 8080

ingress:
  media:
    enabled: true
    className: "ingress-nginx"
    hosts:
      - host: sabnzbd.bjw-s.dev
        paths:
          - path: /
            service:
              name: main
              port: http

persistence:
  media:
    existingClaim: nas-media
    globalMounts:
      - path: /data/nas-media
```

#### Changes in this example

This is not meant as an exhaustive list of changes, but rather a "most common" example.

- `podSecurityContext` has been moved to `defaultPodOptions.securityContext`. It is also possible to configure this on a controller-specific basis by moving it to `controllers.main.pod.securityContext` instead.
- `image` has been moved to `controllers.main.containers.main.image` so that multiple containers can be configured.
- `ingress.media.ingressClassName` has been renamed to `ingress.main.className`.
- `ingress.media.enabled` can be removed, since items are considered enabled by default (they can still be disabled by adding `enabled: false`).
- `ingress.media.hosts.*.paths.*.service` is now required since there is no more concept of a default "primary" service.
- `persistence.media.mountPath` has been moved to `persistence.media.globalMounts.*.path` to allow multiple mountPaths for the same persistence item.
- `persistence.media.enabled` can be removed, since items are considered enabled by default (they can still be disabled by adding `enabled: false`).
- `probes` has been moved to `controllers.main.containers.main.probes` so that multiple containers can be configured.
