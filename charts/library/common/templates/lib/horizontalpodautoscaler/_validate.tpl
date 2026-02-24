{{/*
Validate HorizontalPodAutoscaler values
*/}}
{{- define "bjw-s.common.lib.horizontalPodAutoscaler.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $hpaObject := .object -}}

  {{- if empty (get $hpaObject "controller") -}}
    {{- fail (printf "controller reference is required for HorizontalPodAutoscaler. (HPA %s)" $hpaObject.identifier) -}}
  {{- end -}}

  {{- if empty (get $hpaObject "maxReplicas") -}}
    {{- fail (printf "maxReplicas is required for HorizontalPodAutoscaler. (HPA %s)" $hpaObject.identifier) -}}
  {{- end -}}

  {{- $controllerObject := (include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $hpaObject.controller) | fromYaml) -}}
  {{- if not (has $controllerObject.type (list "deployment" "statefulset")) -}}
    {{- fail (printf "HorizontalPodAutoscaler is only supported for deployment and statefulset controller types. (HPA %s, controller type: %s)" $hpaObject.identifier $controllerObject.type) -}}
  {{- end -}}

{{- end -}}
