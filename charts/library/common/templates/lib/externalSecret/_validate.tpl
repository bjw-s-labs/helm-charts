{{/*
Validate externalSecret values
*/}}
{{- define "bjw-s.common.lib.externalSecret.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $externalSecretObject := .object -}}

  {{- $defaultStoreName := dig "defaultExternalSecretStoreRef" "name" "" $rootContext.Values -}}
  {{- $resourceStoreName := dig "secretStoreRef" "name" "" $externalSecretObject -}}
  {{- $hasDefaultStore := not (empty ($resourceStoreName | default $defaultStoreName)) -}}

  {{- range $index, $dataEntry := ($externalSecretObject.data | default list) -}}
    {{- $sourceStoreName := dig "sourceRef" "storeRef" "name" "" $dataEntry -}}
    {{- if and (not $hasDefaultStore) (empty $sourceStoreName) -}}
      {{- fail (printf "ExternalSecret '%s': data entry %d has no SecretStore reference. Configure a default store, a resource-level store, or 'externalSecrets.%s.data[%d].sourceRef.storeRef'." $externalSecretObject.identifier $index $externalSecretObject.identifier $index) -}}
    {{- end -}}
  {{- end -}}

  {{- range $index, $dataFromEntry := ($externalSecretObject.dataFrom | default list) -}}
    {{- $sourceStoreName := dig "sourceRef" "storeRef" "name" "" $dataFromEntry -}}
    {{- if and (not $hasDefaultStore) (empty $sourceStoreName) -}}
      {{- fail (printf "ExternalSecret '%s': dataFrom entry %d has no SecretStore reference. Configure a default store, a resource-level store, or 'externalSecrets.%s.dataFrom[%d].sourceRef.storeRef'." $externalSecretObject.identifier $index $externalSecretObject.identifier $index) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
