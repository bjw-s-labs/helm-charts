{{/* Common annotations shared across objects */}}
{{- define "bjw-s.common.lib.metadata.globalAnnotations" -}}
  {{- with .Values.global.annotations }}
    {{- range $k, $v := . }}
      {{- $name := $k }}
      {{- $value := include "bjw-s.common.lib.common.renderString" (dict "value" $v "rootContext" $) }}
{{ $name }}: {{ quote $value }}
    {{- end }}
  {{- end }}
{{- end -}}
