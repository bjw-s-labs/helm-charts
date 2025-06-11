{{/*
Autodetects the service for a ServiceMonitors object
*/}}
{{- define "bjw-s.common.lib.serviceMonitor.autoDetectService" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceMonitorObject := .object -}}
  {{- $enabledServices := (include "bjw-s.common.lib.service.enabledServices" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- if eq 1 (len $enabledServices) -}}
    {{- if and
        (empty (dig "selector" nil $serviceMonitorObject))
        (empty (dig "serviceName" nil $serviceMonitorObject))
        (empty (dig "service" "name" nil $serviceMonitorObject))
        (empty (dig "service" "identifier" nil $serviceMonitorObject))
    -}}
      {{- $_ := set $serviceMonitorObject "service" (dict "identifier" ($enabledServices | keys | first)) -}}
    {{- end -}}
  {{- end -}}

  {{- $serviceMonitorObject | toYaml -}}
{{- end -}}
