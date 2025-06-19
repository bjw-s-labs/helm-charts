{{/*
This template serves as a blueprint for generating RoleBinding objects in Kubernetes.
*/}}
{{- define "bjw-s.common.class.rbac.roleBinding" -}}
  {{- $rootContext := .rootContext -}}
  {{- $roleBindingObject := .object -}}

  {{- $labels := merge
    ($roleBindingObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($roleBindingObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- $subjects := list -}}
  {{- with $roleBindingObject.subjects -}}
    {{- range $subject := . -}}
      {{- if hasKey . "identifier" -}}
        {{- $subject := include "bjw-s.common.lib.serviceAccount.getByIdentifier" (dict "rootContext" $rootContext "id" .identifier) | fromYaml -}}
        {{- if not $subject }}
          {{- fail (printf "No enabled ServiceAccount found with this identifier. (rolebinding: '%s', identifier: '%s')" $roleBindingObject.identifier .identifier) -}}
        {{- end -}}
        {{- $subject = pick $subject "name" -}}
        {{- $_ := set $subject "kind" "ServiceAccount" -}}
        {{- $_ := set $subject "namespace" $rootContext.Release.Namespace -}}
        {{- $subjects = mustAppend $subjects $subject -}}
      {{- else if eq .kind "Group" -}}
        {{- $subject := dict "name" .name "kind" .kind -}}
        {{- $subjects = mustAppend $subjects $subject -}}
      {{- else if eq .kind "User" -}}
        {{- $subject := dict "name" .name "kind" .kind -}}
        {{- $subjects = mustAppend $subjects $subject -}}
      {{- else -}}
        {{- if not .namespace }}
          {{- fail (printf "No namespace provided for subject '%s'. Please provide a namespace." $roleBindingObject.name) -}}
        {{- end -}}
        {{- $subject := dict "name" .name "kind" .kind "namespace" .namespace -}}
        {{- $subjects = mustAppend $subjects $subject -}}
      {{- end -}}
    {{- end -}}
    {{- $subjects = $subjects | uniq | toYaml -}}
  {{- end -}}

  {{- $role := dict -}}
  {{- with  $roleBindingObject.roleRef -}}
    {{- if hasKey . "identifier" -}}
      {{- $role = include "bjw-s.common.lib.rbac.role.getByIdentifier" (dict "rootContext" $rootContext "id" .identifier) | fromYaml -}}
    {{- else -}}
      {{- $_ := set $role "name" .name -}}
      {{- $_ := set $role "type" .kind -}}
    {{- end -}}
  {{- end -}}
---
apiVersion: rbac.authorization.k8s.io/v1
{{ with $roleBindingObject.type -}}
kind: {{ . }}
{{ end -}}
metadata:
  name: {{ $roleBindingObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{ if eq $roleBindingObject.type "RoleBinding" -}}
  namespace: {{ $rootContext.Release.Namespace }}
  {{- end }}
roleRef:
  kind: {{ $role.type }}
  name: {{ $role.name }}
  apiGroup: rbac.authorization.k8s.io
{{ with $subjects -}}
subjects: {{- tpl . $rootContext | nindent 2 }}

{{- end -}}

{{- end -}}
