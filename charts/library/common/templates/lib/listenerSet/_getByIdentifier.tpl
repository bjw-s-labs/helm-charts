{{/*
Return a ListenerSet object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.listenerSet.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}

  {{- $enabledListenerSets := (include "bjw-s.common.lib.listenerSet.enabledListenerSets" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledListenerSets $identifier) -}}
    {{- get $enabledListenerSets $identifier | toYaml -}}
  {{- end -}}
{{- end -}}
