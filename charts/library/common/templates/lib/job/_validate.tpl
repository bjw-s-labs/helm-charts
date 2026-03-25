{{/*
Validate job values
*/}}
{{- define "bjw-s.common.lib.job.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $jobValues := .object -}}

  {{- $allowedRestartPolicy := list "Never" "OnFailure" -}}
  {{- if not (has $jobValues.pod.restartPolicy $allowedRestartPolicy) -}}
    {{- fail (printf "Job '%s': Invalid restartPolicy '%s'. Valid options are 'Never' or 'OnFailure'. Specify a valid restartPolicy under 'controllers.%s.pod.restartPolicy'." $jobValues.identifier $jobValues.pod.restartPolicy $jobValues.identifier) -}}
  {{- end -}}
{{- end -}}
