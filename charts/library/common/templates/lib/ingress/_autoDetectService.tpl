{{/*
Autodetects the service for an Ingress object
*/}}
{{- define "bjw-s.common.lib.ingress.autoDetectService" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ingressObject := .object -}}
  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- if eq 1 (len $enabledServices) -}}
    {{- range $ingressObject.hosts -}}
      {{- range .paths -}}
        {{- if not (has "service" (keys .)) -}}
          {{- $_ := set . "service" (dict "identifier" ($enabledServices | keys | first)) -}}
        {{- else if and (not .service.name) (not .service.identifier) -}}
          {{- $_ := set .service "identifier" ($enabledServices | keys | first) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $ingressObject | toYaml -}}
{{- end -}}
