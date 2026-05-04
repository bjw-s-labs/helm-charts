{{/*
Validate Ingress values
*/}}
{{- define "bjw-s.common.lib.ingress.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ingressObject := .object -}}

  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{/* Verify automatic service detection */}}
  {{- if not (eq 1 (len $enabledServices)) -}}
    {{- range $ingressObject.hosts -}}
      {{- $host := . -}}
      {{- range $host.paths -}}
        {{- $path := . -}}
        {{- if or (not (has "service" (keys .))) (and (not $path.service.name) (not $path.service.identifier)) -}}
          {{- fail (printf "Ingress '%s': Either 'service.name' or 'service.identifier' is required for host '%s' path '%s' because automatic Service detection is not possible (found %d enabled services). Specify the target service explicitly." $ingressObject.identifier $host.host $path.path (len $enabledServices)) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

{{- end -}}
