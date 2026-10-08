{{/*
Build a selector targeting one or more controllers.
*/}}
{{- define "bjw-s.common.lib.networkpolicy.controllerSelector" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerIdentifiers := .controllerIdentifiers -}}
  {{- $extraSelectorLabels := .extraSelectorLabels | default dict -}}

  {{- /* Intersect the effective selector labels of all selected controllers. */ -}}
  {{- $matchLabels := dict -}}
  {{- $controllerLabelValues := list -}}
  {{- range $index, $controllerIdentifier := $controllerIdentifiers -}}
    {{- $controllerObject := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $controllerIdentifier) | fromYaml -}}
    {{- $labels := include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | fromYaml -}}
    {{- $controllerLabel := get $labels "app.kubernetes.io/controller" -}}
    {{- if not (has $controllerLabel $controllerLabelValues) -}}
      {{- $controllerLabelValues = append $controllerLabelValues $controllerLabel -}}
    {{- end -}}
    {{- if eq $index 0 -}}
      {{- $matchLabels = deepCopy $labels -}}
    {{- else -}}
      {{- range $key, $value := $matchLabels -}}
        {{- if or (not (hasKey $labels $key)) (ne (get $labels $key) $value) -}}
          {{- $_ := unset $matchLabels $key -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $_ := unset $matchLabels "app.kubernetes.io/controller" -}}
  {{- $matchLabels = mergeOverwrite (dict) $matchLabels $extraSelectorLabels -}}

  {{- /* Put the effective controller label in matchLabels or an In expression. */ -}}
  {{- $selector := dict "matchLabels" $matchLabels -}}
  {{- if not (hasKey $matchLabels "app.kubernetes.io/controller") -}}
    {{- if eq (len $controllerLabelValues) 1 -}}
      {{- $_ := set $matchLabels "app.kubernetes.io/controller" (first $controllerLabelValues) -}}
    {{- else -}}
      {{- $_ := set $selector "matchExpressions" (list (dict
        "key" "app.kubernetes.io/controller"
        "operator" "In"
        "values" (sortAlpha $controllerLabelValues)
      )) -}}
    {{- end -}}
  {{- end -}}
  {{- $selector | toYaml -}}
{{- end -}}
