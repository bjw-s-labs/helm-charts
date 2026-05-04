{{- /*
Returns the value for initContainers
*/ -}}
{{- define "bjw-s.common.lib.pod.field.initContainers" -}}
  {{- $rootContext := .ctx.rootContext -}}
  {{- $controllerObject := .ctx.controllerObject -}}

  {{- /* Default to empty list */ -}}
  {{- $graph := dict -}}
  {{- $containers := list -}}

  {{- /* Fetch configured containers for this controller */ -}}
  {{- $renderedContainers := dict -}}

  {{- range $key, $containerValues := $controllerObject.initContainers -}}
    {{- /* Enable container by default, but allow override */ -}}
    {{- $containerEnabled := true -}}
    {{- if hasKey $containerValues "enabled" -}}
      {{- $containerEnabled = $containerValues.enabled -}}
    {{- end -}}

    {{- if $containerEnabled -}}
      {{- /* Create object from the container values */ -}}
      {{- $containerObject := (include "bjw-s.common.lib.container.valuesToObject" (dict "rootContext" $rootContext "controllerObject" $controllerObject "containerType" "init" "id" $key "values" $containerValues)) | fromYaml -}}

      {{- /* Perform validations on the Container before rendering */ -}}
      {{- include "bjw-s.common.lib.container.validate" (dict "rootContext" $rootContext "controllerObject" $controllerObject "containerObject" $containerObject) -}}

      {{- /* Generate the Container spec */ -}}
      {{- $renderedContainer := include "bjw-s.common.lib.container.spec" (dict "rootContext" $rootContext "controllerObject" $controllerObject "containerObject" $containerObject) | fromYaml -}}
      {{- $_ := set $renderedContainers $key $renderedContainer -}}

      {{- /* Determine the Container order */ -}}
      {{- if empty (dig "dependsOn" nil $containerValues) -}}
        {{- $_ := set $graph $key ( list ) -}}
      {{- else if kindIs "string" $containerValues.dependsOn -}}
        {{- $_ := set $graph $key ( list $containerValues.dependsOn ) -}}
      {{- else if kindIs "slice" $containerValues.dependsOn -}}
        {{- $_ := set $graph $key $containerValues.dependsOn -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Process graph */ -}}
  {{- $args := dict "graph" $graph "out" list "contextType" "initContainer" "contextId" $controllerObject.identifier -}}
  {{- include "bjw-s.common.lib.kahn" $args -}}

  {{- range $name := $args.out -}}
    {{- $containerItem := get $renderedContainers $name -}}
    {{- $containers = append $containers $containerItem -}}
  {{- end -}}

  {{- if not (empty $containers) -}}
    {{- $containers | toYaml -}}
  {{- end -}}
{{- end -}}
