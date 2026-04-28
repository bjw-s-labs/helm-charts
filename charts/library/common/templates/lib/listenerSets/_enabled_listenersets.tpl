{{/*
Return the enabled ListenerSets.
*/}}
{{- define "bjw-s.common.lib.listenerSet.enabledListenerSets" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledListenerSets := dict -}}

  {{- range $name, $listenerSet := $rootContext.Values.listenerSet -}}
    {{- if kindIs "map" $listenerSet -}}
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
    {{- $_ := set $enabledListenerSets $identifier $object -}}
  {{- end -}}

  {{- $enabledListenerSets | toYaml -}}
{{- end -}}
