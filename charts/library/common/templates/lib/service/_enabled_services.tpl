{{/*
Return the enabled services.
*/}}
{{- define "bjw-s.common.lib.service.enabledServices" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledServices := dict -}}

  {{- range $identifier, $objectValues := $rootContext.Values.service -}}
    {{- if kindIs "map" $objectValues -}}
      {{- /* Enable Service by default, but allow override */ -}}
      {{- $serviceEnabled := true -}}
      {{- if hasKey $objectValues "enabled" -}}
        {{- $serviceEnabled = $objectValues.enabled -}}
      {{- end -}}

      {{- if $serviceEnabled -}}
        {{- $_ := set $enabledServices $identifier $objectValues -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $objectValues := $enabledServices -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledServices)) | fromYaml -}}
    {{- $object = include "bjw-s.common.lib.service.autoDetectController" (dict "rootContext" $rootContext "object" $object) | fromYaml -}}
    {{- $_ := set $enabledServices $identifier $object -}}
  {{- end -}}

  {{- $enabledServices | toYaml -}}
{{- end -}}
