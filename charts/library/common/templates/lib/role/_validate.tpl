{{/*
Validate Role values
*/}}
{{- define "bjw-s.common.lib.rbac.role.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $roleValues := .object -}}
  {{- $rules := $roleValues.rules -}}

  {{- if not $rules -}}
    {{- fail (printf "Role '%s': Rules cannot be empty. Define at least one rule under 'roles.%s.rules'." $roleValues.identifier $roleValues.identifier) -}}
  {{- end -}}
{{- end -}}
