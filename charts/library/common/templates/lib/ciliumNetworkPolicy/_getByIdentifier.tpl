{{/*
Return a CiliumNetworkPolicy object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.ciliumNetworkPolicy.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledCiliumNetworkPolicies := (include "bjw-s.common.lib.ciliumNetworkPolicy.enabledCiliumNetworkPolicies" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledCiliumNetworkPolicies $identifier) -}}
    {{- $objectValues := get $enabledCiliumNetworkPolicies $identifier -}}
    {{- include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" (len $enabledCiliumNetworkPolicies)) -}}
  {{- end -}}
{{- end -}}
