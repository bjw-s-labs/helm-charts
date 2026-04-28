{{/*
Validate ListenerSet values
*/}}
{{- define "bjw-s.common.lib.listenerSet.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $listenerSetObject := .object -}}

  {{- if empty $listenerSetObject.parentRef -}}
    {{- fail (printf "ListenerSet '%s': parentRef is required." $listenerSetObject.identifier) -}}
  {{- end -}}

  {{- if empty $listenerSetObject.listeners -}}
    {{- fail (printf "ListenerSet '%s': at least one listener is required." $listenerSetObject.identifier) -}}
  {{- end -}}
{{- end -}}
