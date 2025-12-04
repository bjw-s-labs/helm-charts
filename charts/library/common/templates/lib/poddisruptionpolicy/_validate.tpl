{{/*
Validate PodDisruptionBudget values
*/}}
{{- define "bjw-s.common.lib.podDisruptionBudget.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podDisruptionBudgetObject := .object -}}

  {{- if empty (get $podDisruptionBudgetObject "controller") -}}
    {{- fail (printf "controller reference is required for PodDisruptionBudget. (PodDisruptionBudget %s)" $podDisruptionBudgetObject.identifier) -}}
  {{- end -}}
{{- end -}}
