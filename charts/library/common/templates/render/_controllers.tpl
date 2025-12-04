{{/*
Renders the controller objects required by the chart.
*/}}
{{- define "bjw-s.common.render.controllers" -}}
  {{- $rootContext := $ -}}

  {{- /* Generate named controller objects as required */ -}}
  {{- $enabledControllers := (include "bjw-s.common.lib.controller.enabledControllers" (dict "rootContext" $rootContext) | fromYaml ) -}}
  {{- range $identifier := keys $enabledControllers -}}
    {{- /* Create object from the raw controller values */ -}}
    {{- $controllerObject := (include "bjw-s.common.lib.controller.getByIdentifier" (dict "rootContext" $rootContext "id" $identifier) | fromYaml) -}}

    {{- /* Perform validations on the controller before rendering */ -}}
    {{- include "bjw-s.common.lib.controller.validate" (dict "rootContext" $rootContext "object" $controllerObject) -}}

    {{- if eq $controllerObject.type "deployment" -}}
      {{- $deploymentObject := (include "bjw-s.common.lib.deployment.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $controllerObject "itemCount" (len $enabledControllers))) | fromYaml -}}
      {{- include "bjw-s.common.lib.deployment.validate" (dict "rootContext" $rootContext "object" $deploymentObject) -}}
      {{- include "bjw-s.common.class.deployment" (dict "rootContext" $rootContext "object" $deploymentObject) | nindent 0 -}}

    {{- else if eq $controllerObject.type "cronjob" -}}
      {{- $cronjobObject := (include "bjw-s.common.lib.cronjob.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $controllerObject "itemCount" (len $enabledControllers))) | fromYaml -}}
      {{- include "bjw-s.common.lib.cronjob.validate" (dict "rootContext" $rootContext "object" $cronjobObject) -}}
      {{- include "bjw-s.common.class.cronjob" (dict "rootContext" $rootContext "object" $cronjobObject) | nindent 0 -}}

    {{- else if eq $controllerObject.type "daemonset" -}}
      {{- $daemonsetObject := (include "bjw-s.common.lib.daemonset.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $controllerObject "itemCount" (len $enabledControllers))) | fromYaml -}}
      {{- include "bjw-s.common.lib.daemonset.validate" (dict "rootContext" $rootContext "object" $daemonsetObject) -}}
      {{- include "bjw-s.common.class.daemonset" (dict "rootContext" $rootContext "object" $daemonsetObject) | nindent 0 -}}

    {{- else if eq $controllerObject.type "statefulset"  -}}
      {{- $statefulsetObject := (include "bjw-s.common.lib.statefulset.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $controllerObject "itemCount" (len $enabledControllers))) | fromYaml -}}
      {{- include "bjw-s.common.lib.statefulset.validate" (dict "rootContext" $rootContext "object" $statefulsetObject) -}}
      {{- include "bjw-s.common.class.statefulset" (dict "rootContext" $rootContext "object" $statefulsetObject) | nindent 0 -}}

    {{- else if eq $controllerObject.type "job"  -}}
      {{- $jobObject := (include "bjw-s.common.lib.job.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" $controllerObject "itemCount" (len $enabledControllers))) | fromYaml -}}
      {{- include "bjw-s.common.lib.job.validate" (dict "rootContext" $rootContext "object" $jobObject) -}}
      {{- include "bjw-s.common.class.job" (dict "rootContext" $rootContext "object" $jobObject) | nindent 0 -}}
    {{- end -}}

    {{- if $controllerObject.podDisruptionBudget -}}
      {{- $podDisruptionBudgetObject := (include "bjw-s.common.lib.valuesToObject" (dict "rootContext" $rootContext "id" $identifier "values" (merge (dict "controller" $identifier "forceRename" $controllerObject.name) $controllerObject.podDisruptionBudget))) | fromYaml -}}
      {{- include "bjw-s.common.lib.podDisruptionBudget.validate" (dict "rootContext" $rootContext "object" $podDisruptionBudgetObject) -}}
      {{- include "bjw-s.common.class.podDisruptionBudget" (dict "rootContext" $rootContext "object" $podDisruptionBudgetObject) | nindent 0 -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
