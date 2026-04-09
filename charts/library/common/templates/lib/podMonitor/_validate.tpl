{{/*
Validate podMonitor values
*/}}
{{- define "bjw-s.common.lib.podMonitor.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podMonitorObject := .object -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{/* Verify automatic controller detection */}}
  {{- if not (eq 1 (len $enabledControllers)) -}}
    {{- if and
        (empty (dig "selector" nil $podMonitorObject))
        (empty (dig "controller" "identifier" nil $podMonitorObject))
    -}}
      {{- fail (printf "PodMonitor '%s': Either 'controller.identifier' or 'selector' is required because automatic controller detection is not possible (found %d enabled controllers). Specify the target controller explicitly." $podMonitorObject.identifier (len $enabledControllers)) -}}
    {{- end -}}
  {{- end -}}

  {{- if not $podMonitorObject.podMetricsEndpoints -}}
    {{- fail (printf "PodMonitor '%s': podMetricsEndpoints are required. Define at least one endpoint under 'podMonitor.%s.podMetricsEndpoints'." $podMonitorObject.identifier $podMonitorObject.identifier) -}}
  {{- end -}}
{{- end -}}
