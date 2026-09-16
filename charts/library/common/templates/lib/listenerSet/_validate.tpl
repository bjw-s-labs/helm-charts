{{/*
Validate ListenerSet values
*/}}
{{- define "bjw-s.common.lib.listenerSet.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $listenerSetObject := .object -}}

  {{- /* parentRef is required */ -}}
  {{- if empty $listenerSetObject.parentRef -}}
    {{- fail (printf "ListenerSet '%s': spec.parentRef is required. Define it under 'listenerSets.%s.parentRef' with a Gateway name." $listenerSetObject.identifier $listenerSetObject.identifier) -}}
  {{- end -}}
  {{- if empty $listenerSetObject.parentRef.name -}}
    {{- fail (printf "ListenerSet '%s': parentRef.name is required. Specify the parent Gateway name under 'listenerSets.%s.parentRef.name'." $listenerSetObject.identifier $listenerSetObject.identifier) -}}
  {{- end -}}

  {{- /* At least one listener is required */ -}}
  {{- if empty $listenerSetObject.listeners -}}
    {{- fail (printf "ListenerSet '%s': At least one listener is required. Add entries under 'listenerSets.%s.listeners'." $listenerSetObject.identifier $listenerSetObject.identifier) -}}
  {{- end -}}

  {{- /* Validate each listener */ -}}
  {{- $seenNames := dict -}}
  {{- range $index, $listener := $listenerSetObject.listeners -}}
    {{- $listenerContext := printf "listenerSets.%s.listeners[%d]" $listenerSetObject.identifier $index -}}
    {{- if empty $listener.name -}}
      {{- fail (printf "ListenerSet '%s': Listener at index %d requires a name. Specify it under '%s.name'." $listenerSetObject.identifier $index $listenerContext) -}}
    {{- end -}}
    {{- if hasKey $seenNames $listener.name -}}
      {{- fail (printf "ListenerSet '%s': Listener name '%s' is not unique. Ensure each listener has a unique name under 'listenerSets.%s.listeners'." $listenerSetObject.identifier $listener.name $listenerSetObject.identifier) -}}
    {{- end -}}
    {{- $_ := set $seenNames $listener.name true -}}

    {{- if empty $listener.port -}}
      {{- fail (printf "ListenerSet '%s': Listener '%s' requires a port. Specify it under '%s.port'." $listenerSetObject.identifier $listener.name $listenerContext) -}}
    {{- end -}}

    {{- $protocol := $listener.protocol -}}
    {{- $validProtocols := list "HTTP" "HTTPS" "TCP" "TLS" "UDP" -}}
    {{- if not (has $protocol $validProtocols) -}}
      {{- fail (printf "ListenerSet '%s': Listener '%s' has an invalid protocol '%s'. Must be one of HTTP, HTTPS, TCP, TLS or UDP. Specify it under '%s.protocol'." $listenerSetObject.identifier $listener.name $protocol $listenerContext) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
