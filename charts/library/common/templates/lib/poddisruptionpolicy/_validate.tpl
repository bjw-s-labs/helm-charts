{{/*
Validate PodDisruptionBudget values
*/}}
{{- define "bjw-s.common.lib.podDisruptionBudget.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $podDisruptionBudgetObject := .object -}}

  {{- if empty (get $podDisruptionBudgetObject "controller") -}}
    {{- fail (printf "PodDisruptionBudget '%s': Controller reference is required. Specify a controller under 'podDisruptionBudgets.%s.controller'." $podDisruptionBudgetObject.identifier $podDisruptionBudgetObject.identifier) -}}
  {{- end -}}
{{- end -}}
