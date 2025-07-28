---
hide:
  - toc
---

# Image

!!! warning
**IMPORTANT** This feature requires Kubernetes version >= 1.33 and a compatible container runtime!

When you want to mount the contents of an OCI object (a container image or artifact)
you will want to use the `image` persistence type.

See the [Kubernetes docs](https://kubernetes.io/docs/concepts/storage/volumes/#image)
for more information.

| Field        | Mandatory | Docs / Description                 |
| ------------ | --------- | ---------------------------------- |
| `image`      | Yes       | OCI artifact reference to be used. |
| `pullPolicy` | No        | Configure the image pull behavior. |

## Minimal configuration

```yaml
persistence:
  config:
    type: image
    image: quay.io/crio/artifact:v2
```

This will create an image volume based on the `quay.io/crio/artifact:v2` OCI artifact and mount it to `/config`.
