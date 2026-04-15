{{/*
Convert RawResource values to an object
*/}}
{{- define "bjw-s.common.lib.rawResource.valuesToObject" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $objectValues := .values -}}
  {{- $itemCount := .itemCount -}}

  {{- $objectName := (include "bjw-s.common.lib.determineResourceNameFromValues" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" $itemCount)) -}}

  {{- $manifest := $objectValues.manifest -}}

  {{- /* Set computed metadata on the manifest */ -}}
  {{- $_ := set $manifest "name" $objectName -}}
  {{- $_ := set $manifest "identifier" $identifier -}}

  {{- $manifest | toYaml -}}
{{- end -}}
