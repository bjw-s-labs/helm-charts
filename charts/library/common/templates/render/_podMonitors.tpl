{{/*
Renders the podMonitor objects required by the chart.
*/}}
{{- define "bjw-s.common.render.podMonitors" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate named podMonitors as required */ -}}
  {{- $enabledPodMonitors := (include "bjw-s.common.lib.podMonitor.enabledPodMonitors" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledPodMonitors -}}
    {{- /* Generate object from the raw podMonitor values */ -}}
    {{- $podMonitorObject := (include "bjw-s.common.lib.podMonitor.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the PodMonitor before rendering */ -}}
    {{- include "bjw-s.common.lib.podMonitor.validate" (dict "rootContext" $rootContext "object" $podMonitorObject) -}}

    {{- /* Include the PodMonitor class */ -}}
    {{- include "bjw-s.common.class.podMonitor" (dict "rootContext" $rootContext "object" $podMonitorObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}
