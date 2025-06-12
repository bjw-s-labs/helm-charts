{{- /*
Returns the value for the specified field
*/ -}}
{{- define "bjw-s.common.lib.pod.getOption" -}}
  {{- $rootContext := .ctx.rootContext -}}
  {{- $controllerObject := .ctx.controllerObject -}}
  {{- $option := .option -}}
  {{- $default := default nil .default -}}
  {{- $value := $default -}}

  {{- $defaultPodOptionsStrategy := dig "defaultPodOptionsStrategy" "overwrite" $rootContext.Values -}}

  {{- /* Set to the default Pod option if one is set */ -}}
  {{- $defaultPodOption := dig $option nil (default dict $rootContext.Values.defaultPodOptions) -}}
  {{- if kindIs "bool" $defaultPodOption -}}
    {{- $value = $defaultPodOption -}}
  {{- else if not (empty $defaultPodOption) -}}
    {{- $value = $defaultPodOption -}}
  {{- end -}}

  {{- /* See if a pod-specific override is needed */ -}}
  {{- $podSpecificOption := dig $option nil (default dict $controllerObject.pod) -}}

  {{- if kindIs "bool" $podSpecificOption -}}
    {{- $value = $podSpecificOption -}}
  {{- else if kindIs "map" $podSpecificOption -}}
    {{- if eq "merge" $defaultPodOptionsStrategy -}}
      {{- $value = merge $podSpecificOption $value -}}
    {{- else if eq "overwrite" $defaultPodOptionsStrategy -}}
      {{- $value = $podSpecificOption -}}
    {{- end -}}
  {{- else if not (empty $podSpecificOption) -}}
    {{- $value = $podSpecificOption -}}
  {{- end -}}

  {{- if kindIs "bool" $value -}}
    {{- $value | toYaml -}}
  {{- else if not (empty $value) -}}
    {{- $value | toYaml -}}
  {{- end -}}
{{- end -}}
