{{/*
Build a selector targeting one or more controllers.
*/}}
{{- define "bjw-s.common.lib.networkpolicy.controllerSelector" -}}
  {{- $rootContext := .rootContext -}}
  {{- $object := .object -}}
  {{- $resourceKind := .resourceKind -}}

  {{- /* Get the available controller identifiers */ -}}
  {{- $enabledControllers := include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml -}}
  {{- $availableControllers := keys $enabledControllers | sortAlpha -}}
  {{- $controllerIdentifiers := list -}}

  {{- /* Resolve the configured controller references */ -}}
  {{- if $object.controllers -}}
    {{- range $controllerReference := $object.controllers -}}
      {{- $matches := list -}}
      {{- if has $controllerReference $availableControllers -}}
        {{- $matches = list $controllerReference -}}
      {{- else if ne (regexQuoteMeta $controllerReference) $controllerReference -}}
        {{- $expression := printf "^(%s)$" $controllerReference -}}
        {{- range $controllerIdentifier := $availableControllers -}}
          {{- if mustRegexMatch $expression $controllerIdentifier -}}
            {{- $matches = append $matches $controllerIdentifier -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- if empty $matches -}}
        {{- fail (printf "%s '%s': Controller reference '%s' matched no enabled controllers. Update 'networkpolicies.%s.controllers' to match one of: [%s]." $resourceKind $object.identifier $controllerReference $object.identifier (join ", " $availableControllers)) -}}
      {{- end -}}
      {{- range $controllerIdentifier := $matches -}}
        {{- if not (has $controllerIdentifier $controllerIdentifiers) -}}
          {{- $controllerIdentifiers = append $controllerIdentifiers $controllerIdentifier -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $controllerIdentifiers = sortAlpha $controllerIdentifiers -}}
  {{- else if $object.controller -}}
    {{- if not (has $object.controller $availableControllers) -}}
      {{- fail (printf "%s '%s': No enabled controller found with identifier '%s'. Update 'networkpolicies.%s.controller' or enable the controller under 'controllers.%s'. Available controllers: [%s]." $resourceKind $object.identifier $object.controller $object.identifier $object.controller (join ", " $availableControllers)) -}}
    {{- end -}}
    {{- $controllerIdentifiers = list $object.controller -}}
  {{- else if eq (len $availableControllers) 1 -}}
    {{- $controllerIdentifiers = $availableControllers -}}
  {{- end -}}

  {{- /* Use a matchLabel when targeting a single controller */ -}}
  {{- $matchLabels := include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml -}}
  {{- if eq (len $controllerIdentifiers) 1 -}}
    {{- $_ := set $matchLabels "app.kubernetes.io/controller" (first $controllerIdentifiers) -}}
  {{- end -}}
  {{- $matchLabels = mergeOverwrite (dict) $matchLabels ($object.extraSelectorLabels | default dict) -}}

  {{- /* Use a matchExpression when targeting multiple controllers */ -}}
  {{- $selector := dict "matchLabels" $matchLabels -}}
  {{- if and
    (gt (len $controllerIdentifiers) 1)
    (not (hasKey ($object.extraSelectorLabels | default dict) "app.kubernetes.io/controller"))
  -}}
    {{- $_ := set $selector "matchExpressions" (list (dict
      "key" "app.kubernetes.io/controller"
      "operator" "In"
      "values" $controllerIdentifiers
    )) -}}
  {{- end -}}
  {{- $selector | toYaml -}}
{{- end -}}
