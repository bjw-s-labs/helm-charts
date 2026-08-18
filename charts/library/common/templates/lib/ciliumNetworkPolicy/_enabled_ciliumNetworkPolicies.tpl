{{/*
Return the enabled CiliumNetworkPolicies.
*/}}
{{- define "bjw-s.common.lib.ciliumNetworkPolicy.enabledCiliumNetworkPolicies" -}}
  {{- $rootContext := .rootContext -}}
  {{- $enabledCiliumNetworkPolicies := dict -}}

  {{- range $name, $ciliumNetworkPolicy := $rootContext.Values.ciliumNetworkPolicies -}}
    {{- if kindIs "map" $ciliumNetworkPolicy -}}
      {{- /* Enable by default, but allow override */ -}}
      {{- $ciliumNetworkPolicyEnabled := true -}}
      {{- if hasKey $ciliumNetworkPolicy "enabled" -}}
        {{- $ciliumNetworkPolicyEnabled = $ciliumNetworkPolicy.enabled -}}
      {{- end -}}

      {{- if $ciliumNetworkPolicyEnabled -}}
        {{- $_ := set $enabledCiliumNetworkPolicies $name . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $enabledCiliumNetworkPolicies | toYaml -}}
{{- end -}}
