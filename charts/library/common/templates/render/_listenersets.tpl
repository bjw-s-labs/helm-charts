{{/*
Renders the ListenerSet objects required by the chart
*/}}
{{- define "bjw-s.common.render.listenerSets" -}}
  {{- $rootContext := $ -}}

  {{- $enabledListenerSets := (include "bjw-s.common.lib.listenerSet.enabledListenerSets" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledListenerSets -}}
    {{- $listenerSetObject := (include "bjw-s.common.lib.listenerSet.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- include "bjw-s.common.lib.listenerSet.validate" (dict "rootContext" $rootContext "object" $listenerSetObject) -}}

    {{- include "bjw-s.common.class.listenerSet" (dict "rootContext" $rootContext "object" $listenerSetObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}
