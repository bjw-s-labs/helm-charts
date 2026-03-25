{{/*
Validate StatefulSet values
*/}}
{{- define "bjw-s.common.lib.statefulset.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $statefulsetValues := .object -}}

  {{- if and (ne $statefulsetValues.strategy "OnDelete") (ne $statefulsetValues.strategy "RollingUpdate") -}}
    {{- fail (printf "StatefulSet '%s': Invalid strategy type '%s'. Valid options are 'OnDelete' or 'RollingUpdate'. Specify a valid strategy under 'controllers.%s.strategy'." $statefulsetValues.identifier $statefulsetValues.strategy $statefulsetValues.identifier) -}}
  {{- end -}}

  {{- if not (empty (dig "statefulset" "volumeClaimTemplates" "" $statefulsetValues)) -}}
    {{- range $index, $volumeClaimTemplate := $statefulsetValues.statefulset.volumeClaimTemplates -}}
      {{- if empty (get . "size") -}}
        {{- fail (printf "StatefulSet '%s': VolumeClaimTemplate '%s' requires a 'size' field. Define the size under 'controllers.%s.statefulset.volumeClaimTemplates.%s.size'." $statefulsetValues.identifier $volumeClaimTemplate.name $statefulsetValues.identifier $volumeClaimTemplate.name) -}}
      {{- end -}}

      {{- if empty (get . "accessMode") -}}
        {{- fail (printf "StatefulSet '%s': VolumeClaimTemplate '%s' requires an 'accessMode' field. Define the accessMode under 'controllers.%s.statefulset.volumeClaimTemplates.%s.accessMode'." $statefulsetValues.identifier $volumeClaimTemplate.name $statefulsetValues.identifier $volumeClaimTemplate.name) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
