{{/*
Image used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.image" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $containerObject := $ctx.containerObject -}}

  {{- $imageRepo := tpl $containerObject.image.repository $rootContext -}}
  {{- $imageTag := tpl $containerObject.image.tag $rootContext -}}
  {{- $imageDigest := tpl $containerObject.image.digest $rootContext -}}

  {{- if and $imageRepo $imageTag -}}
    {{- if $imageDigest -}}
      {{- printf "%s:%s@%s" $imageRepo $imageTag $imageDigest -}}
    {{- else -}}
      {{- printf "%s:%s" $imageRepo $imageTag -}}
    {{- end -}}
  {{- else if and $imageRepo $imageDigest }}
      {{- printf "%s@%s" $imageRepo $imageDigest -}}
  {{- end -}}
{{- end -}}
