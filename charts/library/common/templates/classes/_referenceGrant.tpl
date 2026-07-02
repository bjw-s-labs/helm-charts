{{/*
This template renders a ReferenceGrant object that authorizes a Route in a different namespace to reference Services in the release namespace.
It returns empty output when no cross-namespace reference is detected.
*/}}
{{- define "bjw-s.common.class.route.referenceGrant" -}}
  {{- $rootContext := .rootContext -}}
  {{- $routeObject := .object -}}

  {{- $routeKind := $routeObject.kind | default "HTTPRoute" -}}
  {{- $routeNamespace := $routeObject.namespaceOverride | default $rootContext.Release.Namespace -}}
  {{- /* Determine API version */ -}}
  {{- $apiVersion := "gateway.networking.k8s.io/v1alpha2" -}}
  {{- if $rootContext.Capabilities.APIVersions.Has (printf "gateway.networking.k8s.io/v1beta1/ReferenceGrant") }}
    {{- $apiVersion = "gateway.networking.k8s.io/v1beta1" -}}
  {{- end -}}
  {{- if $rootContext.Capabilities.APIVersions.Has (printf "gateway.networking.k8s.io/v1/ReferenceGrant") }}
    {{- $apiVersion = "gateway.networking.k8s.io/v1" -}}
  {{- end -}}

  {{- /* Only generate a grant when the route is in a different namespace */ -}}
  {{- if ne $routeNamespace $rootContext.Release.Namespace -}}
    {{- $grantEnabled := true -}}
    {{- if hasKey $routeObject "referenceGrant" -}}
      {{- if hasKey $routeObject.referenceGrant "enabled" -}}
        {{- $grantEnabled = $routeObject.referenceGrant.enabled -}}
      {{- end -}}
    {{- end -}}

    {{- if $grantEnabled -}}
      {{- /* Resolve backendRefs and collect Service names in the release namespace */ -}}
      {{- $serviceNames := list -}}
      {{- range $routeObject.rules -}}
        {{- range .backendRefs -}}
          {{- $backendRef := . -}}
          {{- $serviceName := "" -}}
          {{- $serviceNamespace := "" -}}
          {{- if .name -}}
            {{- $serviceName = tpl .name $rootContext -}}
            {{- $serviceNamespace = .namespace | default $rootContext.Release.Namespace -}}
          {{- else if .identifier -}}
            {{- $service := (include "bjw-s.common.lib.service.getByIdentifier" (dict "rootContext" $rootContext "id" .identifier) | fromYaml ) -}}
            {{- if $service -}}
              {{- $serviceName = $service.name -}}
              {{- $serviceNamespace = $rootContext.Release.Namespace -}}
            {{- end -}}
          {{- end -}}
          {{- /* Only include Services in the release namespace */ -}}
          {{- if and $serviceName (eq $serviceNamespace $rootContext.Release.Namespace) -}}
            {{- if not (has $serviceName $serviceNames) -}}
              {{- $serviceNames = append $serviceNames $serviceName -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- /* Only render if there are services to grant access to */ -}}
      {{- if $serviceNames -}}
        {{- $labels := merge
          ($routeObject.labels | default dict)
          (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
        -}}
        {{- $annotations := merge
          ($routeObject.annotations | default dict)
          (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
        -}}
---
apiVersion: {{ $apiVersion }}
kind: ReferenceGrant
metadata:
  name: {{ $routeObject.name }}
  namespace: {{ $rootContext.Release.Namespace }}
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
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: {{ $routeKind }}
      namespace: {{ $routeNamespace }}
  to:
    {{- range $serviceName := $serviceNames }}
    - group: ""
      kind: Service
      name: {{ $serviceName }}
    {{- end }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
