{{/*
Implementation of Kahn's algorithm based on
https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm

source: https://github.com/dastrobu/helm-charts/blob/main/environment-variables/templates/_kahn.tpl
*/}}
{{- define "bjw-s.common.lib.kahn" -}}
  {{- $graph := .graph -}}
  {{- if empty $graph -}}
    {{- $_ := set . "out" list -}}
  {{- else -}}
    {{- /* Validate that all dependencies exist in the graph */ -}}
    {{- $contextType := .contextType | default "graph" -}}
    {{- $contextId := .contextId | default "" -}}
    {{- range $node, $edges := $graph -}}
      {{- range $dependency := $edges -}}
        {{- if not (hasKey $graph $dependency) -}}
          {{- $availableNodes := keys $graph | sortAlpha -}}
          {{- $errorMsg := "" -}}
          {{- if eq $contextType "container" -}}
            {{- $errorMsg = printf "Container '%s': References non-existent container '%s' in dependsOn. Available containers: [%s]" $node $dependency (join ", " $availableNodes) -}}
          {{- else if eq $contextType "initContainer" -}}
            {{- $errorMsg = printf "Init container '%s': References non-existent init container '%s' in dependsOn. Available init containers: [%s]" $node $dependency (join ", " $availableNodes) -}}
          {{- else if eq $contextType "env" -}}
            {{- $errorMsg = printf "Environment variable '%s': References non-existent environment variable '%s' in dependsOn for container '%s'. Available environment variables: [%s]" $node $dependency $contextId (join ", " $availableNodes) -}}
          {{- else -}}
            {{- $errorMsg = printf "Node '%s': References non-existent dependency '%s'. Available nodes: [%s]" $node $dependency (join ", " $availableNodes) -}}
          {{- end -}}
          {{- fail $errorMsg -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- $S := list -}}

    {{- range $node, $edges := $graph -}}
      {{- if empty $edges -}}
        {{- $S = append $S $node -}}
      {{- end -}}
    {{- end -}}

    {{- if empty $S -}}
      {{- $errorPrefix := "" -}}
      {{- if eq $contextType "container" -}}
        {{- $errorPrefix = printf "Cyclic dependency detected in container ordering for controller '%s'. " $contextId -}}
      {{- else if eq $contextType "initContainer" -}}
        {{- $errorPrefix = printf "Cyclic dependency detected in initContainer ordering for controller '%s'. " $contextId -}}
      {{- else if eq $contextType "env" -}}
        {{- $errorPrefix = printf "Cyclic dependency detected in environment variable ordering for container '%s'. " $contextId -}}
      {{- else -}}
        {{- $errorPrefix = "Graph is cyclic or has bad edge definitions. " -}}
      {{- end -}}
      {{- $suggestions := "" -}}
      {{- if or (eq $contextType "container") (eq $contextType "initContainer") -}}
        {{- $suggestions = "Check the 'dependsOn' fields in your container definitions to ensure there are no circular dependencies. " -}}
      {{- else if eq $contextType "env" -}}
        {{- $suggestions = "Check the 'dependsOn' fields in your environment variable definitions to ensure there are no circular dependencies. " -}}
      {{- end -}}
      {{- fail (printf "%s%sRemaining nodes: [%s]" $errorPrefix $suggestions (keys $graph | sortAlpha | join ", ")) -}}
    {{- end -}}

    {{- $n := first $S -}}
    {{- $_ := unset $graph $n -}}

    {{- range $node, $edges := $graph -}}
      {{- $_ := set $graph $node ( without $edges $n ) -}}
    {{- end -}}

    {{- $args := dict "graph" $graph "out" list "contextType" .contextType "contextId" .contextId -}}
    {{- include "bjw-s.common.lib.kahn" $args -}}
    {{- $_ = set . "out" ( concat ( list $n ) $args.out ) -}}
  {{- end -}}
{{- end }}
