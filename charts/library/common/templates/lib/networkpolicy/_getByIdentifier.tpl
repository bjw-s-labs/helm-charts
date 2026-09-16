{{/*
Return a NetworkPolicy object by its Identifier.
*/}}
{{- define "bjw-s.common.lib.networkpolicy.getByIdentifier" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $enabledNetworkPolicies := (include "bjw-s.common.lib.networkpolicy.enabledNetworkPolicies" (dict "rootContext" $rootContext) | fromYaml ) }}

  {{- if (hasKey $enabledNetworkPolicies $identifier) -}}
    {{- $objectValues := get $enabledNetworkPolicies $identifier -}}
    {{- $itemCount := len $enabledNetworkPolicies -}}
    {{- include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $objectValues "itemCount" $itemCount) -}}
  {{- end -}}
{{- end -}}
