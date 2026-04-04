{{/*
Return a PodMonitor Object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.podMonitor.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledPodMonitors := (include "bjw-s.common.lib.podMonitor.enabledPodMonitors" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledPodMonitors $identifier) -}}
    {{- $objectValues := get $enabledPodMonitors $identifier -}}
    {{- include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledPodMonitors)) -}}
  {{- end -}}
{{- end -}}
