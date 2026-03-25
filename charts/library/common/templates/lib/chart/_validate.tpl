{{/*
Validate global chart values
*/}}
{{- define "bjw-s.common.lib.chart.validate" -}}
  {{- $rootContext := . -}}

  {{- /* Validate persistence values */ -}}
  {{- range $persistenceKey, $persistenceValues := .Values.persistence }}
    {{- $persistenceEnabled := true -}}
    {{- if hasKey $persistenceValues "enabled" -}}
      {{- $persistenceEnabled = $persistenceValues.enabled -}}
    {{- end -}}

    {{- if $persistenceEnabled -}}
      {{- /* Make sure that any advancedMounts controller references actually resolve */ -}}
      {{- range $key, $advancedMount := $persistenceValues.advancedMounts -}}
          {{- $mountController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $key) -}}
          {{- if empty $mountController -}}
            {{- fail (printf "Persistence '%s': No enabled controller found with identifier '%s'. Ensure a controller with this identifier exists and is enabled under 'controllers.%s'." $persistenceKey $key $key) -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
