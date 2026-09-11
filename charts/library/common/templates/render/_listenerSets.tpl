{{/*
Renders the ListenerSet objects required by the chart
*/}}
{{- define "bjw-s.common.render.listenerSets" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate named ListenerSets as required */ -}}
  {{- $enabledListenerSets := (include "bjw-s.common.lib.listenerSet.enabledListenerSets" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledListenerSets -}}
    {{- /* Generate object from the raw ListenerSet values */ -}}
    {{- $listenerSetObject := (include "bjw-s.common.lib.listenerSet.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the ListenerSet before rendering */ -}}
    {{- include "bjw-s.common.lib.listenerSet.validate" (dict "rootContext" $rootContext "object" $listenerSetObject) -}}

    {{- /* Include the ListenerSet class */ -}}
    {{- include "bjw-s.common.class.listenerSet" (dict "rootContext" $rootContext "object" $listenerSetObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}
