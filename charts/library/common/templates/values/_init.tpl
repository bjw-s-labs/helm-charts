{{/*
Merge the local chart values and the common chart defaults
*/}}
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
