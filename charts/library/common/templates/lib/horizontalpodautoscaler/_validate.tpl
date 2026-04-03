{{/*
Validate HorizontalPodAutoscaler values
*/}}
{{- define "bjw-s.common.lib.horizontalPodAutoscaler.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $horizontalPodAutoscalerObject := .object -}}

  {{- if empty (get $horizontalPodAutoscalerObject "controller") -}}
    {{- fail (printf "controller reference is required for HorizontalPodAutoscaler. (HorizontalPodAutoscaler %s)" $horizontalPodAutoscalerObject.identifier) -}}
  {{- end -}}

  {{- if empty (get $horizontalPodAutoscalerObject "maxReplicas") -}}
    {{- fail (printf "maxReplicas is required for HorizontalPodAutoscaler. (HorizontalPodAutoscaler %s)" $horizontalPodAutoscalerObject.identifier) -}}
  {{- end -}}
{{- end -}}
