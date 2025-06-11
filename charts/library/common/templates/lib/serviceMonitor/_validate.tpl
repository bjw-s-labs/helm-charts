{{/*
Validate serviceMonitor values
*/}}
{{- define "bjw-s.common.lib.serviceMonitor.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceMonitorObject := .object -}}

  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{/* Verify automatic controller detection */}}
  {{- if not (eq 1 (len $enabledServices)) -}}
    {{- if and
        (empty (dig "selector" nil $serviceMonitorObject))
        (empty (dig "serviceName" nil $serviceMonitorObject))
        (empty (dig "service" "name" nil $serviceMonitorObject))
        (empty (dig "service" "identifier" nil $serviceMonitorObject))
    -}}
      {{- fail (printf "Either service.name or service.identifier is required because automatic Service detection is not possible. (serviceMonitor: %s)" $serviceMonitorObject.identifier ) -}}
    {{- end -}}
  {{- end -}}

  {{- if not $serviceMonitorObject.endpoints -}}
    {{- fail (printf "endpoints are required for serviceMonitor with key \"%v\"" $serviceMonitorObject.identifier) -}}
  {{- end -}}
{{- end -}}
