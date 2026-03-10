{{- /*
Returns the value for annotations
*/ -}}
{{- define "bjw-s.common.lib.pod.metadata.annotations" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerObject := .controllerObject -}}

  {{- /* Default annotations */ -}}
  {{- $annotations := merge
    (dict)
  -}}

  {{- /* Include global annotations if specified */ -}}
  {{- if $rootContext.Values.global.propagateGlobalMetadataToPods -}}
    {{- $annotations = merge
      (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
      $annotations
    -}}
  {{- end -}}

  {{- /* Fetch the configured annotations */ -}}
  {{- $ctx := dict "rootContext" $rootContext "controllerObject" $controllerObject -}}
  {{- $podAnnotations := (include "bjw-s.common.lib.pod.getOption" (dict "ctx" $ctx "option" "annotations")) | fromYaml -}}
  {{- if not (empty $podAnnotations) -}}
    {{- $annotations = merge
      $podAnnotations
      $annotations
    -}}
  {{- end -}}

  {{- /* Add configMaps checksum */ -}}
  {{- $configMapsFound := dict -}}
  {{- range $name, $configmap := $rootContext.Values.configMaps -}}
    {{- $configMapEnabled := true -}}
    {{- if hasKey $configmap "enabled" -}}
      {{- $configMapEnabled = $configmap.enabled -}}
    {{- end -}}
    {{- $configMapIncludeInChecksum := true -}}
    {{- if hasKey $configmap "includeInChecksum" -}}
      {{- $configMapIncludeInChecksum = $configmap.includeInChecksum -}}
    {{- end -}}
    {{- /* Check if this controller should get the checksum */ -}}
    {{- $includeChecksumInControllers := list -}}
    {{- if hasKey $configmap "includeChecksumInControllers" -}}
      {{- $includeChecksumInControllers = $configmap.includeChecksumInControllers -}}
    {{- end -}}
    {{- $configMapChecksumAddToController := or (empty $includeChecksumInControllers) (has $controllerObject.identifier $includeChecksumInControllers) -}}
    {{- if and $configMapEnabled $configMapIncludeInChecksum $configMapChecksumAddToController -}}
      {{- $_ := set $configMapsFound $name (tpl (toYaml $configmap.data) $rootContext | sha256sum) -}}
    {{- end -}}
  {{- end -}}
  {{- if $configMapsFound -}}
    {{- $annotations = merge
      (dict "checksum/configMaps" (toYaml $configMapsFound | sha256sum))
      $annotations
    -}}
  {{- end -}}

  {{- /* Add Secrets checksum */ -}}
  {{- $secretsFound := dict -}}
  {{- range $name, $secret := $rootContext.Values.secrets -}}
    {{- $secretEnabled := true -}}
    {{- if hasKey $secret "enabled" -}}
      {{- $secretEnabled = $secret.enabled -}}
    {{- end -}}
    {{- $secretIncludeInChecksum := true -}}
    {{- if hasKey $secret "includeInChecksum" -}}
      {{- $secretIncludeInChecksum = $secret.includeInChecksum -}}
    {{- end -}}
    {{- /* Check if this controller should get the checksum */ -}}
    {{- $includeChecksumInControllers := list -}}
    {{- if hasKey $secret "includeChecksumInControllers" -}}
      {{- $includeChecksumInControllers = $secret.includeChecksumInControllers -}}
    {{- end -}}
    {{- $secretChecksumAddToController := or (empty $includeChecksumInControllers) (has $controllerObject.identifier $includeChecksumInControllers) -}}
    {{- if and $secretEnabled $secretIncludeInChecksum $secretChecksumAddToController -}}
      {{- $_ := set $secretsFound $name (tpl (toYaml $secret.stringData) $rootContext | sha256sum) -}}
    {{- end -}}
  {{- end -}}
  {{- if $secretsFound -}}
    {{- $annotations = merge
      (dict "checksum/secrets" (toYaml $secretsFound | sha256sum))
      $annotations
    -}}
  {{- end -}}

  {{- if not (empty $annotations) -}}
    {{- tpl (toYaml $annotations) $rootContext -}}
  {{- end -}}
{{- end -}}
