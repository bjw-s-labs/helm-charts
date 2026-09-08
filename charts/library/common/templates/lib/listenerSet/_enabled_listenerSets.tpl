{{/*
Return the enabled ListenerSets with their computed name, identifier and
detected API version metadata (apiVersion, kind, group).
*/}}
{{- define "bjw-s.common.lib.listenerSet.enabledListenerSets" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledListenerSets := dict -}}

  {{- range $name, $listenerSet := $rootContext.Values.listenerSets -}}
    {{- if kindIs "map" $listenerSet -}}
      {{- /* Enable ListenerSet by default, but allow override */ -}}
      {{- $listenerSetEnabled := true -}}
      {{- if hasKey $listenerSet "enabled" -}}
        {{- $listenerSetEnabled = $listenerSet.enabled -}}
      {{- end -}}

      {{- if $listenerSetEnabled -}}
        {{- $_ := set $enabledListenerSets $name . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $identifier, $objectValues := $enabledListenerSets -}}
    {{- $object := include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledListenerSets)) | fromYaml -}}
    {{- $apiVersionInfo := include "bjw-s.common.lib.listenerSet.apiVersion" (dict "rootContext" $rootContext "identifier" $identifier) | fromYaml -}}
    {{- $object = merge $object $apiVersionInfo -}}
    {{- $_ := set $enabledListenerSets $identifier $object -}}
  {{- end -}}

  {{- $enabledListenerSets | toYaml -}}
{{- end -}}
