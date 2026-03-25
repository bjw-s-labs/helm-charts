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
        {{- fail (printf "RoleBinding '%s': Subject kind is required. Specify a kind (User, Group, or ServiceAccount) for each subject under 'roleBindings.%s.subjects'." $roleBindingValues.identifier $roleBindingValues.identifier) -}}
      {{- end -}}
    {{- end -}}

    {{- if eq $subjectTypeCount 0 -}}
      {{- fail (printf "RoleBinding '%s': At least one subject with a valid kind is required. Add subjects under 'roleBindings.%s.subjects'." $roleBindingValues.identifier $roleBindingValues.identifier) -}}
    {{- end -}}

  {{- else -}}
    {{- fail (printf "RoleBinding '%s': Both 'subjects' and 'roleRef' are required. Define subjects and roleRef under 'roleBindings.%s'." $roleBindingValues.identifier $roleBindingValues.identifier) -}}
  {{- end -}}
{{- end -}}
