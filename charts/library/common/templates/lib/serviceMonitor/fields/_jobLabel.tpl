{{- /*
Returns the value for serviceMonitor jobLabel
*/ -}}
{{- define "bjw-s.common.lib.serviceMonitor.field.jobLabel" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $serviceMonitorObject := $ctx.serviceMonitorObject -}}

  {{- if $serviceMonitorObject.jobLabel -}}
    {{- include "bjw-s.common.lib.common.renderString" (dict "value" $serviceMonitorObject.jobLabel "rootContext" $rootContext) -}}
  {{- else -}}
    app.kubernetes.io/name
  {{- end -}}
{{- end -}}
