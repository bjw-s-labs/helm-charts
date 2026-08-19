{{/*
Renders the ExternalSecret objects required by the chart.
*/}}
{{- define "bjw-s.common.render.externalSecrets" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate named ExternalSecrets as required */ -}}
  {{- $enabledExternalSecrets := (include "bjw-s.common.lib.externalSecret.enabledExternalSecrets" (dict "rootContext" $rootContext) | fromYaml ) -}}

  {{- range $identifier := keys $enabledExternalSecrets -}}
    {{- /* Generate object from the raw externalSecret values */ -}}
    {{- $externalSecretObject := (include "bjw-s.common.lib.externalSecret.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the ExternalSecret before rendering */ -}}
    {{- include "bjw-s.common.lib.externalSecret.validate" (dict "rootContext" $rootContext "object" $externalSecretObject) -}}

    {{- /* Include the ExternalSecret class */ -}}
    {{- include "bjw-s.common.class.externalSecret" (dict "rootContext" $rootContext "object" $externalSecretObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}
