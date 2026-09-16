{{/*
Merge the local chart values and the common chart defaults
*/}}
{{/*
Strings are evaluated against the post-merge root context.
ExternalSecret target template data is intentionally deferred for downstream evaluation.
*/}}
{{- define "bjw-s.common.values.evaluateTemplate" -}}
  {{- $value := .value -}}
  {{- $rootContext := .rootContext -}}
  {{- $path := .path | default list -}}
  {{- $deferTpl := .deferTpl | default false -}}
  {{- $passes := .passes -}}
  {{- $excludePaths := .excludePaths -}}
  {{- $result := $value -}}
  {{- if kindIs "map" $value -}}
    {{- $result = dict -}}
    {{- range $key, $item := $value -}}
      {{- $itemPath := append $path (toString $key) -}}
      {{- $itemDeferTpl := $deferTpl -}}
      {{- /* ExternalSecret target.template.data is evaluated later by ESO with fetched keys such as .username and .password, so preserve its expressions. */ -}}
      {{- if and (eq (len $itemPath) 5) (eq (index $itemPath 0) "externalSecrets") (eq (index $itemPath 2) "target") (eq (index $itemPath 3) "template") (eq (index $itemPath 4) "data") -}}
        {{- $itemDeferTpl = true -}}
      {{- end -}}
      {{- $itemResult := include "bjw-s.common.values.evaluateTemplate" (dict "rootContext" $rootContext "value" $item "path" $itemPath "deferTpl" $itemDeferTpl "passes" $passes "excludePaths" $excludePaths) | fromJson -}}
      {{- $_ := set $result $key (index $itemResult "value") -}}
    {{- end -}}
  {{- else if kindIs "slice" $value -}}
    {{- $result = list -}}
    {{- range $index, $item := $value -}}
      {{- $itemPath := append $path (toString $index) -}}
      {{- $itemResult := include "bjw-s.common.values.evaluateTemplate" (dict "rootContext" $rootContext "value" $item "path" $itemPath "deferTpl" $deferTpl "passes" $passes "excludePaths" $excludePaths) | fromJson -}}
      {{- $result = append $result (index $itemResult "value") -}}
    {{- end -}}
  {{- else if kindIs "string" $value -}}
    {{- if not $deferTpl -}}
      {{- $excluded := false -}}
      {{- range $excludePath := $excludePaths -}}
        {{- if and (le (len $excludePath) (len $path)) (deepEqual $excludePath (slice $path 0 (len $excludePath))) -}}
          {{- $excluded = true -}}
        {{- end -}}
      {{- end -}}
      {{- $stringPasses := ternary 0 $passes $excluded -}}
      {{- range until ($stringPasses | int) -}}
        {{- if not (contains "{{" $result) -}}
          {{- break -}}
        {{- end -}}
        {{- $rendered := tpl $result $rootContext -}}
        {{- if eq $rendered $result -}}
          {{- break -}}
        {{- end -}}
        {{- $result = $rendered -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- toJson (dict "value" $result) -}}
{{- end -}}

{{- define "bjw-s.common.values.init" -}}
  {{- if .Values.common -}}
    {{- $defaultValues := deepCopy .Values.common -}}
    {{- $userValues := deepCopy (omit .Values "common") -}}
    {{- /* Determine if we should create a default serviceAccount */ -}}
    {{- $createDefaultSA := true -}}
    {{- if hasKey $userValues "global" -}}
      {{- if hasKey $userValues.global "createDefaultServiceAccount" -}}
        {{- $createDefaultSA = $userValues.global.createDefaultServiceAccount -}}
      {{- end -}}
    {{- end -}}
    {{- /* Inject default serviceAccount using release name as identifier if enabled and no SA provided */ -}}
    {{- if and $createDefaultSA (not (hasKey $userValues "serviceAccount")) -}}
      {{- $saIdentifier := .Release.Name -}}
      {{- $_ := set $defaultValues "serviceAccount" (dict $saIdentifier dict) -}}
    {{- end -}}
    {{- $mergedValues := mustMergeOverwrite $defaultValues $userValues -}}
    {{- $_ := set . "Values" (deepCopy $mergedValues) -}}
  {{- end -}}
{{- end -}}
