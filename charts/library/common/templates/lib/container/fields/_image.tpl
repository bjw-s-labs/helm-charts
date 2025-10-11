{{/*
Image used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.image" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $containerObject := $ctx.containerObject -}}

  {{- include "bjw-s.common.lib.imageSpecificationToImage" (dict "rootContext" $rootContext "imageSpec" $containerObject.image) -}}
{{- end -}}
