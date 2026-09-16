{{/*
Return the enabled externalSecrets.
*/}}
{{- define "bjw-s.common.lib.externalSecret.enabledExternalSecrets" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledExternalSecrets := dict -}}

  {{- range $identifier, $externalSecret := $rootContext.Values.externalSecrets -}}
    {{- if kindIs "map" $externalSecret -}}
      {{- /* Enable ExternalSecret by default, but allow override */ -}}
      {{- $externalSecretEnabled := true -}}
      {{- if hasKey $externalSecret "enabled" -}}
        {{- $externalSecretEnabled = $externalSecret.enabled -}}
      {{- end -}}

      {{- if $externalSecretEnabled -}}
        {{- $_ := set $enabledExternalSecrets $identifier . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $enabledExternalSecrets | toYaml -}}
{{- end -}}
