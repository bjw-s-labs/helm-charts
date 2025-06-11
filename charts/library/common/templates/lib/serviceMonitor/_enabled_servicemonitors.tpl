{{/*
Return the enabled serviceMonitors.
*/}}
{{- define "bjw-s.common.lib.serviceMonitor.enabledServiceMonitors" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledServiceMonitors := dict -}}

  {{- range $identifier, $serviceMonitor := $rootContext.Values.serviceMonitor -}}
    {{- if kindIs "map" $serviceMonitor -}}
      {{- /* Enable serviceMonitors by default, but allow override */ -}}
      {{- $serviceMonitorEnabled := true -}}
      {{- if hasKey $serviceMonitor "enabled" -}}
        {{- $serviceMonitorEnabled = $serviceMonitor.enabled -}}
      {{- end -}}

      {{- if $serviceMonitorEnabled -}}
        {{- $_ := set $enabledServiceMonitors $identifier . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $objectValues := $enabledServiceMonitors -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledServiceMonitors)) | fromYaml -}}
    {{- $object = include "bjw-s.common.lib.serviceMonitor.autoDetectService" (dict "rootContext" $rootContext "object" $object) | fromYaml -}}
    {{- $_ := set $enabledServiceMonitors $identifier $object -}}
  {{- end -}}

  {{- $enabledServiceMonitors | toYaml -}}
{{- end -}}
