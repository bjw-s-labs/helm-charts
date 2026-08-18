{{/*
Renders the ciliumNetworkPolicy objects required by the chart.
*/}}
{{- define "bjw-s.common.render.ciliumNetworkPolicies" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate ciliumNetworkPolicy as required */ -}}
  {{- $enabledCiliumNetworkPolicies := (include "bjw-s.common.lib.ciliumNetworkPolicy.enabledCiliumNetworkPolicies" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledCiliumNetworkPolicies -}}
    {{- /* Generate object from the raw persistence values */ -}}
    {{- $ciliumNetworkPolicyObject := (include "bjw-s.common.lib.ciliumNetworkPolicy.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the ciliumNetworkPolicy before rendering */ -}}
    {{- include "bjw-s.common.lib.ciliumNetworkPolicy.validate" (dict "rootContext" $ "object" $ciliumNetworkPolicyObject) -}}

    {{- /* Include the ciliumNetworkPolicy class */ -}}
    {{- include "bjw-s.common.class.ciliumNetworkPolicy" (dict "rootContext" $ "object" $ciliumNetworkPolicyObject) | nindent 0 -}}
  {{- end -}}
{{- end -}}
