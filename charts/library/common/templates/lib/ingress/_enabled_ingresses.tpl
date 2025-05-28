{{/*
Return the enabled Ingresses.
*/}}
{{- define "bjw-s.common.lib.ingress.enabledIngresses" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledIngress := dict -}}

  {{- range $name, $ingress := $rootContext.Values.ingress -}}
    {{- if kindIs "map" $ingress -}}
      {{- /* Enable by default, but allow override */ -}}
      {{- $ingressEnabled := true -}}
      {{- if hasKey $ingress "enabled" -}}
        {{- $ingressEnabled = $ingress.enabled -}}
      {{- end -}}

      {{- if $ingressEnabled -}}
        {{- $_ := set $enabledIngress $name . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $objectValues := $enabledIngress -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledIngress)) | fromYaml -}}
    {{- $object = include "bjw-s.common.lib.ingress.autoDetectService" (dict "rootContext" $rootContext "object" $object) | fromYaml -}}
    {{- $_ := set $enabledIngress $identifier $object -}}
  {{- end -}}

  {{- $enabledIngress | toYaml -}}
{{- end -}}
