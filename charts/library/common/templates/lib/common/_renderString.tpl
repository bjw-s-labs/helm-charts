{{/*
Return a centrally evaluated string, or render content loaded from chart files.
*/}}
{{- define "bjw-s.common.lib.common.renderString" -}}
  {{- $render := .render | default false -}}
  {{- $valuesRendered := false -}}
  {{- if typeIs "map[string]interface {}" .rootContext -}}
    {{- $valuesRendered = dig "TemplateRendering" "valuesRendered" false .rootContext -}}
  {{- end -}}
  {{- if or $render (not $valuesRendered) -}}
    {{- tpl .value .rootContext -}}
  {{- else -}}
    {{- .value -}}
  {{- end -}}
{{- end -}}
