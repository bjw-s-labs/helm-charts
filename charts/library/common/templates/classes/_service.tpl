{{/*
This template serves as a blueprint for all Service objects that are created
within the common library.
*/}}
{{- define "bjw-s.common.class.service" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .object -}}

  {{- $svcType := default "ClusterIP" $serviceObject.type -}}
  {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}
  {{- $labels := mergeOverwrite
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
    (dict "app.kubernetes.io/service" $serviceObject.name)
    ($serviceObject.labels | default dict)
  -}}
  {{- $annotations := mergeOverwrite
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
    ($serviceObject.annotations | default dict)
  -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (include "bjw-s.common.lib.common.renderString" (dict "value" $value "rootContext" $rootContext) | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (include "bjw-s.common.lib.common.renderString" (dict "value" $value "rootContext" $rootContext) | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
spec:
  {{- if (eq $svcType "ClusterIP") }}
  type: ClusterIP
  {{- else if eq $svcType "LoadBalancer" }}
  type: {{ $svcType }}
  {{- if $serviceObject.loadBalancerIP }}
  loadBalancerIP: {{ $serviceObject.loadBalancerIP }}
  {{- end }}
  {{- if $serviceObject.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{ toYaml $serviceObject.loadBalancerSourceRanges | nindent 4 }}
  {{- end -}}
  {{- if $serviceObject.loadBalancerClass }}
  loadBalancerClass: {{ $serviceObject.loadBalancerClass }}
  {{- end -}}
  {{- else if eq $svcType "ExternalName" }}
  type: {{ $svcType }}
  {{- if $serviceObject.externalName }}
  externalName: {{ $serviceObject.externalName }}
  {{- end }}
  {{- else }}
  type: {{ $svcType }}
  {{- end }}
  {{- if and (ne $svcType "ExternalName") $serviceObject.clusterIP }}
  clusterIP: {{ $serviceObject.clusterIP }}
  {{- end }}
  {{- if $serviceObject.internalTrafficPolicy }}
  internalTrafficPolicy: {{ $serviceObject.internalTrafficPolicy }}
  {{- end }}
  {{- if $serviceObject.externalTrafficPolicy }}
  externalTrafficPolicy: {{ $serviceObject.externalTrafficPolicy }}
  {{- end }}
  {{- if hasKey $serviceObject "allocateLoadBalancerNodePorts" }}
  allocateLoadBalancerNodePorts: {{ $serviceObject.allocateLoadBalancerNodePorts }}
  {{- end }}
  {{- if $serviceObject.sessionAffinity }}
  sessionAffinity: {{ $serviceObject.sessionAffinity }}
  {{- if $serviceObject.sessionAffinityConfig }}
  sessionAffinityConfig:
    {{ toYaml $serviceObject.sessionAffinityConfig | nindent 4 }}
  {{- end -}}
  {{- end }}
  {{- with $serviceObject.externalIPs }}
  externalIPs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $serviceObject.publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ $serviceObject.publishNotReadyAddresses }}
  {{- end }}
  {{- if $serviceObject.ipFamilyPolicy }}
  ipFamilyPolicy: {{ $serviceObject.ipFamilyPolicy }}
  {{- end }}
  {{- with $serviceObject.ipFamilies }}
  ipFamilies:
    {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- if and (ge ($rootContext.Capabilities.KubeVersion.Minor | int) 33) ($serviceObject.trafficDistribution) }}
  trafficDistribution: {{ $serviceObject.trafficDistribution }}
  {{- end }}
  ports:
  {{- range $name, $port := $enabledPorts }}
    {{- $portProtocol := "TCP" }}
    {{- if $port.protocol }}
      {{- if not (has $port.protocol (list "HTTP" "HTTPS" "TCP")) }}
        {{- $portProtocol = $port.protocol }}
      {{- end }}
    {{- end }}
    {{- if $port.port }}
    - port: {{ $port.port }}
      targetPort: {{ $port.targetPort | default $port.port }}
      protocol: {{ $portProtocol }}
      name: {{ $name }}
        {{- if (not (empty $port.nodePort)) }}
      nodePort: {{ $port.nodePort }}
        {{ end }}
        {{- if (not (empty $port.appProtocol)) }}
      appProtocol: {{ $port.appProtocol }}
        {{ end }}
    {{- else if $port.portRange }}
      {{- range $portnum := untilStep ($port.portRange.start | int) ((add $port.portRange.end 1) | int) 1 }}
    - port: {{ $portnum }}
      name: {{ $name }}-{{ $portnum }}
      targetPort: {{ $portnum }}
      protocol: {{ $portProtocol }}
        {{- if (not (empty $port.appProtocol)) }}
      appProtocol: {{ $port.appProtocol }}
        {{ end }}
      {{- end }}
    {{- end }}
  {{- end -}}
  {{- $controllerObject := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $serviceObject.controller) | fromYaml -}}
  {{- with (merge
    ($serviceObject.extraSelectorLabels | default dict)
    (include "bjw-s.common.lib.controller.metadata.selectorLabels" (dict "rootContext" $rootContext "controllerObject" $controllerObject) | fromYaml)
  ) }}
  selector: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
