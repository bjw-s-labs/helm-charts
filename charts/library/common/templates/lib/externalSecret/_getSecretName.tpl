{{/*
Return the name of the Secret that is managed by an ExternalSecret object.
*/}}
{{- define "bjw-s.common.lib.externalSecret.getSecretName" -}}
  {{- $externalSecretObject := . -}}
  {{- dig "target" "name" "" $externalSecretObject | default $externalSecretObject.name -}}
{{- end -}}
