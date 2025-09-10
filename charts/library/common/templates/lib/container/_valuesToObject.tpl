{{/*
Convert container values to an object
*/}}
{{- define "bjw-s.common.lib.container.valuesToObject" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerObject := mustDeepCopy .controllerObject -}}
  {{- $containerType := .containerType -}}
  {{- $identifier := .id -}}
  {{- $objectValues := mustDeepCopy .values -}}
  {{- $defaultContainerOptionsStrategy := dig "defaultContainerOptionsStrategy" "overwrite" $controllerObject -}}
  {{- $mergeDefaultContainerOptions := true -}}

  {{- $_ := set $objectValues "identifier" $identifier -}}

  {{- /* Allow disabling default options for initContainers */ -}}
  {{- if (eq "init" $containerType) -}}
    {{- $applyDefaultContainerOptionsToInitContainers := dig "applyDefaultContainerOptionsToInitContainers" true $controllerObject -}}
    {{- if (not (eq $applyDefaultContainerOptionsToInitContainers true)) -}}
      {{- $mergeDefaultContainerOptions = false -}}
    {{- end -}}
  {{- end -}}

  {{- /* Merge default container options if required */ -}}
  {{- if (eq true $mergeDefaultContainerOptions) -}}
    {{- if eq "overwrite" $defaultContainerOptionsStrategy -}}
      {{- range $key, $defaultValue := (dig "defaultContainerOptions" dict $controllerObject) }}
        {{- $specificValue := dig $key nil $objectValues -}}
        {{- if not (empty $specificValue) -}}
          {{- $_ := set $objectValues $key $specificValue -}}
        {{- else -}}
          {{- $_ := set $objectValues $key $defaultValue -}}
        {{- end -}}
      {{- end -}}
    {{- else if eq "merge" $defaultContainerOptionsStrategy -}}
      {{- $objectValues = merge $objectValues (dig "defaultContainerOptions" dict $controllerObject) -}}
    {{- end -}}
  {{- end -}}

  {{- /* Process image tags */ -}}
  {{- if kindIs "map" $objectValues.image -}}
    {{- $imageTag := dig "image" "tag" "" $objectValues -}}
    {{- /* Convert float64 image tags to string */ -}}
    {{- if kindIs "float64" $imageTag -}}
      {{- $imageTag = $imageTag | toString -}}
    {{- end -}}

    {{- $_ := set $objectValues.image "tag" $imageTag -}}
  {{- end -}}

  {{- /* Return the container object */ -}}
  {{- $objectValues | toYaml -}}
{{- end -}}
