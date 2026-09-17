{{/*
Determine a recourse name based on Helm values
*/}}
{{- define "bjw-s.common.lib.determineResourceNameFromValues" -}}
  {{- $rootContext := .rootContext -}}
  {{- $identifier := .id -}}
  {{- $objectValues := .values -}}
  {{- $itemCount := .itemCount -}}

  {{- $objectName := (include "bjw-s.common.lib.chart.names.fullname" $rootContext) -}}

  {{- if $objectValues.forceRename -}}
    {{- $objectName = include "bjw-s.common.lib.common.renderString" (dict "value" $objectValues.forceRename "rootContext" $rootContext) -}}
  {{- else -}}
    {{- if not (empty $objectValues.prefix) -}}
      {{- $renderedPrefix := (include "bjw-s.common.lib.common.renderString" (dict "value" $objectValues.prefix "rootContext" $rootContext)) -}}
      {{- if not (eq $objectName $renderedPrefix) -}}
        {{- $objectName = printf "%s-%s" $renderedPrefix $objectName -}}
      {{- end -}}
    {{- end -}}

    {{- if not (empty $itemCount) -}}
      {{- if or (gt $itemCount 1) ($rootContext.Values.global.alwaysAppendIdentifierToResourceName) -}}
        {{- if and
          (not (hasSuffix (printf "-%s" $identifier) $objectName))
          (not (eq $identifier $objectName))
        -}}
          {{- $objectName = printf "%s-%s" $objectName $identifier -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- if not (empty $objectValues.suffix) -}}
      {{- $renderedSuffix := (include "bjw-s.common.lib.common.renderString" (dict "value" $objectValues.suffix "rootContext" $rootContext)) -}}
      {{- if not (hasSuffix (printf "-%s" $renderedSuffix) $objectName) -}}
        {{- $objectName = printf "%s-%s" $objectName $renderedSuffix -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $objectName | lower -}}
{{- end -}}
