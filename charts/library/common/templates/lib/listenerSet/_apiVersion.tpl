{{/*
Return the ListenerSet API version metadata.

ListenerSet is only available through the standard Gateway API channel:
gateway.networking.k8s.io/v1/ListenerSet.

Returns a dict with `apiVersion`, `kind` and `group`:
- Standard: gateway.networking.k8s.io/v1/ListenerSet
*/}}
{{- define "bjw-s.common.lib.listenerSet.apiVersion" -}}
  {{- (dict "apiVersion" "gateway.networking.k8s.io/v1" "kind" "ListenerSet" "group" "gateway.networking.k8s.io") | toYaml -}}
{{- end -}}
