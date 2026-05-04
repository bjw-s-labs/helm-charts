{{/*
Return a RawResource Object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.rawResource.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledRawResources := (include "bjw-s.common.lib.rawResource.enabledRawResources" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledRawResources $identifier) -}}
    {{- $objectValues := get $enabledRawResources $identifier -}}
    {{- include "bjw-s.common.lib.rawResource.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledRawResources)) -}}
  {{- end -}}
{{- end -}}
