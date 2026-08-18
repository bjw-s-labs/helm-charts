{{/*
This template serves as a blueprint for all ciliumNetworkPolicy objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.ciliumNetworkPolicy" -}}
  {{- $rootContext := .rootContext -}}
  {{- $ciliumNetworkPolicyObject := .object -}}

  {{- $labels := merge
    ($ciliumNetworkPolicyObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($ciliumNetworkPolicyObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
  {{- $endpointSelector := dict -}}
  {{- if (hasKey $ciliumNetworkPolicyObject "endpointSelector") -}}
    {{- $endpointSelector = $ciliumNetworkPolicyObject.endpointSelector -}}
  {{- else -}}
    {{- /* Determine the controller identifier to use */ -}}
    {{- $controllerIdentifier := "" -}}
    {{- if and (hasKey $ciliumNetworkPolicyObject "controller") $ciliumNetworkPolicyObject.controller -}}
      {{- $controllerIdentifier = $ciliumNetworkPolicyObject.controller -}}
    {{- else -}}
      {{- /* Auto-detect: if only one controller exists, use it */ -}}
      {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml) -}}
      {{- if eq (len $enabledControllers) 1 -}}
        {{- $controllerIdentifier = keys $enabledControllers | first -}}
      {{- end -}}
    {{- end -}}

    {{- /* Build the endpoint selector */ -}}
    {{- $selectorLabels := dict "app.kubernetes.io/controller" $controllerIdentifier -}}
    {{- /* Add global selector labels first */ -}}
    {{- $selectorLabels = merge
      (include "bjw-s.common.lib.metadata.selectorLabels" $rootContext | fromYaml)
      $selectorLabels
    -}}
    {{- /* Add extra selector labels last (takes precedence) */ -}}
    {{- if hasKey $ciliumNetworkPolicyObject "extraSelectorLabels" -}}
      {{- $selectorLabels = merge
        $selectorLabels
        ($ciliumNetworkPolicyObject.extraSelectorLabels | default dict)
      -}}
    {{- end -}}
    {{- $endpointSelector = dict "matchLabels" $selectorLabels -}}
  {{- end -}}
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: {{ $ciliumNetworkPolicyObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  endpointSelector: {{- toYaml $endpointSelector | nindent 4 }}
  {{- with $ciliumNetworkPolicyObject.description }}
  description: {{ tpl . $rootContext | quote }}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.ingress }}
  ingress: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.ingressDeny }}
  ingressDeny: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.egress }}
  egress: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.egressDeny }}
  egressDeny: {{- tpl (toYaml .) $rootContext | nindent 4 -}}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.enableDefaultDeny }}
  enableDefaultDeny: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ciliumNetworkPolicyObject.log }}
  log:
    value: {{ . | quote }}
  {{- end }}
{{- end -}}
