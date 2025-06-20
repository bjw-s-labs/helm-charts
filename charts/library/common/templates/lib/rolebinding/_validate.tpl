{{/*
Validate RoleBinding values
*/}}
{{- define "bjw-s.common.lib.rbac.rolebinding.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $roleBindingValues := .object -}}
  {{- $rules := $roleBindingValues.rules -}}

  {{/* Verify permutations for RoleBinding subjects */}}
  {{- if and (not (empty $roleBindingValues.subjects)) (not (empty $roleBindingValues.roleRef)) -}}
    {{- $subjectTypes := list "User" "Group" "ServiceAccount" -}}
    {{- $subjectTypeCount := 0 -}}
    {{- range $roleBindingValues.subjects -}}
      {{- if hasKey . "kind" -}}
        {{- if dict $subjectTypes has .kind -}}
          {{- $subjectTypeCount = add $subjectTypeCount 1 -}}
        {{- else -}}
          {{- fail (printf "Invalid subject kind '%s' in RoleBinding '%s'. Valid kinds are: %s" .kind $roleBindingValues.identifier (join ", " $subjectTypes)) -}}
        {{- end -}}
      {{- else -}}
        {{- fail (printf "Subject kind is required in RoleBinding '%s'" $roleBindingValues.identifier) -}}
      {{- end -}}
    {{- end -}}

    {{- if eq $subjectTypeCount 0 -}}
      {{- fail (printf "At least one subject with a valid kind is required in RoleBinding '%s'" $roleBindingValues.identifier) -}}
    {{- end -}}

  {{- else -}}
    {{- fail (printf "subjects and roleRef are required for RoleBinding with key \"%v\"" $roleBindingValues.identifier) -}}
  {{- end -}}
{{- end -}}
