{{/*
Validate Service values
*/}}
{{- define "bjw-s.common.lib.service.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceObject := .object -}}

  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}

  {{/* Verify automatic controller detection */}}
  {{- if not (eq 1 (len $enabledControllers)) -}}
    {{- if or (not (has "controller" (keys $serviceObject))) (empty (get $serviceObject "controller")) -}}
      {{- fail (printf "controller field is required because automatic controller detection is not possible. (service: %s)" $serviceObject.identifier ) -}}
    {{- end -}}
  {{- end -}}

  {{- if empty (get $serviceObject "controller") -}}
    {{- fail (printf "controller field is required for Service. (service: %s)" $serviceObject.identifier) -}}
  {{- end -}}

  {{- $serviceController := include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $serviceObject.controller) -}}
  {{- if empty $serviceController -}}
    {{- fail (printf "No enabled controller found with this identifier. (service: '%s', controller: '%s')" $serviceObject.identifier $serviceObject.controller) -}}
  {{- end -}}

  {{- /* Validate Service type */ -}}
  {{- $validServiceTypes := (list "ClusterIP" "LoadBalancer" "NodePort" "ExternalName" "ExternalIP") -}}
  {{- if and $serviceObject.type (not (mustHas $serviceObject.type $validServiceTypes)) -}}
    {{- fail (
      printf "invalid service type \"%s\" for Service with key \"%s\". Allowed values are [%s]"
      $serviceObject.type
      $serviceObject.identifier
      (join ", " $validServiceTypes)
    ) -}}
  {{- end -}}

  {{- if ne $serviceObject.type "ExternalName" -}}
    {{- $enabledPorts := include "bjw-s.common.lib.service.enabledPorts" (dict "rootContext" $rootContext "serviceObject" $serviceObject) | fromYaml }}
    {{- /* Validate at least one port is enabled */ -}}
    {{- if not $enabledPorts -}}
      {{- fail (printf "No ports are enabled for Service with this identifier. (service: '%s')" $serviceObject.identifier) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
