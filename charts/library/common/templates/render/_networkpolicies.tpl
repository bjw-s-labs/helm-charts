{{/*
Renders the networkPolicy objects required by the chart.
*/}}
{{- define "bjw-s.common.render.networkpolicies" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate networkPolicy as required */ -}}
  {{- $enabledNetworkPolicies := (include "bjw-s.common.lib.networkpolicy.enabledNetworkPolicies" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledNetworkPolicies -}}
    {{- /* Generate object from the raw persistence values */ -}}
    {{- $networkPolicyObject := (include "bjw-s.common.lib.networkpolicy.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- if eq ($networkPolicyObject.type | default "native") "cilium" -}}
      {{- include "bjw-s.common.lib.ciliumNetworkPolicy.validate" (dict "rootContext" $ "object" $networkPolicyObject) -}}
      {{- include "bjw-s.common.class.ciliumNetworkPolicy" (dict "rootContext" $ "object" $networkPolicyObject) | nindent 0 -}}
    {{- else -}}
      {{- include "bjw-s.common.lib.networkpolicy.validate" (dict "rootContext" $ "object" $networkPolicyObject) -}}
      {{- include "bjw-s.common.class.networkpolicy" (dict "rootContext" $ "object" $networkPolicyObject) | nindent 0 -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
