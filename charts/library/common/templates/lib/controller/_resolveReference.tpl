{{/* Expand and deduplicate exact controller identifiers and anchored regular expressions. */}}
{{- define "bjw-s.common.lib.controller.resolveReferences" -}}
  {{- $rootContext := .rootContext -}}
  {{- $resourceKind := .resourceKind -}}
  {{- $policyIdentifier := .policyIdentifier -}}
  {{- $referencePath := .referencePath -}}
  {{- $enabledControllers := include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml -}}
  {{- $availableControllers := keys $enabledControllers | sortAlpha -}}
  {{- $identifiers := list -}}
  {{- range $reference := .references -}}
    {{- $matches := list -}}
    {{- if has $reference $availableControllers -}}
      {{- $matches = list $reference -}}
    {{- else if hasKey ($rootContext.Values.controllers | default dict) $reference -}}
      {{- /* An existing but disabled identifier must not fall through to regex matching. */ -}}
    {{- else if ne (regexQuoteMeta $reference) $reference -}}
      {{- $expression := printf "^(%s)$" $reference -}}
      {{- /* regexMatch returns false for invalid patterns; the empty alternative matches any valid pattern. */ -}}
      {{- if not (regexMatch (printf "(?:%s)|^$" $expression) "") -}}
        {{- fail (printf "%s '%s': Controller reference '%s' is not a valid regular expression. Fix '%s'." $resourceKind $policyIdentifier $reference $referencePath) -}}
      {{- end -}}
      {{- range $controllerIdentifier := $availableControllers -}}
        {{- if mustRegexMatch $expression $controllerIdentifier -}}
          {{- $matches = append $matches $controllerIdentifier -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- if empty $matches -}}
      {{- fail (printf "%s '%s': Controller reference '%s' matched no enabled controllers. Update '%s' to match one of: [%s]." $resourceKind $policyIdentifier $reference $referencePath (join ", " $availableControllers)) -}}
    {{- end -}}
    {{- range $identifier := $matches -}}
      {{- if not (has $identifier $identifiers) -}}
        {{- $identifiers = append $identifiers $identifier -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- sortAlpha $identifiers | toYaml -}}
{{- end -}}
