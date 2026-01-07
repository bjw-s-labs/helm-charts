{{- /*
Returns the value for serviceMonitor jobLabel
*/ -}}
{{- define "bjw-s.common.lib.serviceMonitor.field.jobLabel" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $serviceMonitorObject := $ctx.serviceMonitorObject -}}

  {{- if $serviceMonitorObject.jobLabel -}}
    {{- tpl $serviceMonitorObject.jobLabel $rootContext -}}
  {{- else -}}
    {{- /* TODO: Change this to app.kubernetes.io/name in v5 */ -}}
    {{- $serviceMonitorObject.name -}}
  {{- end -}}
{{- end -}}
