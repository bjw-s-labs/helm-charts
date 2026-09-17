
{{/*
Translate an imageSpecification to an image string.
*/}}
{{- define "bjw-s.common.lib.imageSpecificationToImage" -}}
  {{- $rootContext := .rootContext -}}
  {{- $imageSpec := .imageSpec -}}

  {{- $imageRepo := include "bjw-s.common.lib.common.renderString" (dict "value" $imageSpec.repository "rootContext" $rootContext) -}}
  {{- $imageTag := include "bjw-s.common.lib.common.renderString" (dict "value" (default "" $imageSpec.tag) "rootContext" $rootContext) -}}
  {{- $imageDigest := include "bjw-s.common.lib.common.renderString" (dict "value" (default "" $imageSpec.digest) "rootContext" $rootContext) -}}

  {{- $image := $imageRepo -}}
  {{- if $imageTag -}}
    {{- $image = printf "%s:%s" $image $imageTag -}}
  {{- end -}}
  {{- if $imageDigest -}}
    {{- $image = printf "%s@%s" $image $imageDigest -}}
  {{- end -}}
  {{- $image -}}
{{- end -}}
