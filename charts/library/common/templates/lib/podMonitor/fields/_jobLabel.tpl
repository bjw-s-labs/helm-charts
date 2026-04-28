{{- /*
Returns the value for podMonitor jobLabel
*/ -}}
{{- define "bjw-s.common.lib.podMonitor.field.jobLabel" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $podMonitorObject := $ctx.podMonitorObject -}}

  {{- if $podMonitorObject.jobLabel -}}
    {{- tpl $podMonitorObject.jobLabel $rootContext -}}
  {{- else -}}
    app.kubernetes.io/name
  {{- end -}}
{{- end -}}
