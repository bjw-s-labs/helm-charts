
{{/*
Translate an imageSpecification to an image string.
*/}}
{{- define "bjw-s.common.lib.imageSpecificationToImage" -}}
  {{- $rootContext := .rootContext -}}
  {{- $imageSpec := .imageSpec -}}

  {{- $imageRepo := tpl $imageSpec.repository $rootContext -}}
  {{- $imageTag := tpl (default "" $imageSpec.tag) $rootContext -}}
  {{- $imageDigest := tpl (default "" $imageSpec.digest) $rootContext -}}

  {{- $image := $imageRepo -}}
  {{- if $imageTag -}}
    {{- $image = printf "%s:%s" $image $imageTag -}}
  {{- end -}}
  {{- if $imageDigest -}}
    {{- $image = printf "%s@%s" $image $imageDigest -}}
  {{- end -}}
  {{- $image -}}
{{- end -}}
