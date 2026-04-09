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
    {{- $podMonitorObject.name -}}
  {{- end -}}
{{- end -}}
