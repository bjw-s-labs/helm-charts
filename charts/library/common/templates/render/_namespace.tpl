{{/*
Renders the Namespace object required by the chart.
*/}}
{{- define "bjw-s.common.render.namespace" -}}
  {{- $rootContext := $ -}}

  {{- if $rootContext.Values.namespace.create -}}
    {{- include "bjw-s.common.class.namespace" (dict "rootContext" $rootContext "object" $rootContext.Values.namespace) | nindent 0 -}}
  {{- end -}}
{{- end -}}
