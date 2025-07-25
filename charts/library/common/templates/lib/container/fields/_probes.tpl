{{/*
Probes used by the container.
*/}}
{{- define "bjw-s.common.lib.container.field.probes" -}}
  {{- $ctx := .ctx -}}
  {{- $rootContext := $ctx.rootContext -}}
  {{- $controllerObject := $ctx.controllerObject -}}
  {{- $containerObject := $ctx.containerObject -}}

  {{- /* Default to empty dict */ -}}
  {{- $enabledProbes := dict -}}

  {{- range $probeName, $probeValues := $containerObject.probes -}}
    {{- /* Disable probe by default, but allow override */ -}}
    {{- $probeEnabled := false -}}
    {{- if hasKey $probeValues "enabled" -}}
      {{- $probeEnabled = $probeValues.enabled -}}
    {{- end -}}

    {{- if $probeEnabled -}}
      {{- $probeDefinition := dict -}}

      {{- if $probeValues.custom -}}
        {{- $parsedProbeSpec := tpl ($probeValues.spec | toYaml) $rootContext -}}
        {{- $probeDefinition = $parsedProbeSpec | fromYaml -}}
      {{- else -}}
        {{- $probeSpec := dig "spec" dict $probeValues -}}

        {{- $primaryService := include "bjw-s.common.lib.service.primaryForController" (dict "rootContext" $rootContext "controllerIdentifier" $controllerObject.identifier) | fromYaml -}}
        {{- $primaryServiceDefaultPort := dict -}}
        {{- if $primaryService -}}
          {{- $primaryServiceDefaultPort = include "bjw-s.common.lib.service.primaryPort" (dict "rootContext" $rootContext "serviceObject" $primaryService) | fromYaml -}}
        {{- end -}}

        {{- $_ := set $probeDefinition "initialDelaySeconds" (include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $probeSpec.initialDelaySeconds "default" 0) | int) -}}
        {{- $_ := set $probeDefinition "failureThreshold" (include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $probeSpec.failureThreshold "default" 3) | int) -}}
        {{- $_ := set $probeDefinition "timeoutSeconds" (include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $probeSpec.timeoutSeconds "default" 1) | int) -}}
        {{- $_ := set $probeDefinition "periodSeconds" (include "bjw-s.common.lib.defaultKeepNonNullValue" (dict "value" $probeSpec.periodSeconds "default" 10) | int) -}}

        {{- $probeType := "" -}}
        {{- $probeHeader := "" -}}

        {{- /* Determine probe type */ -}}
        {{- if eq $probeValues.type "AUTO" -}}
          {{- $probeType = $primaryServiceDefaultPort.protocol -}}
        {{- else -}}
          {{- $probeType = $probeValues.type | default "TCP" -}}
        {{- end -}}

        {{- /* HTTP(S) probe configuration */ -}}
        {{- if or ( eq $probeType "HTTPS" ) ( eq $probeType "HTTP" ) -}}
          {{- $probeHeader = "httpGet" -}}
          {{- $_ := set $probeDefinition $probeHeader (
            dict
              "path" $probeValues.path
              "scheme" $probeType
            )
          -}}

        {{- /* GPRC probe configuration */ -}}
        {{- else if (eq $probeType "GRPC") -}}
          {{- $probeHeader = "grpc" -}}
          {{- $_ := set $probeDefinition $probeHeader dict -}}
            {{- if $probeValues.service -}}
              {{- $_ := set (index $probeDefinition $probeHeader) "service" $probeValues.service -}}
            {{- end -}}

        {{- /* default to tcpSocket probe */ -}}
        {{- else -}}
          {{- $probeHeader = "tcpSocket" -}}
          {{- $_ := set $probeDefinition $probeHeader dict -}}
        {{- end -}}

        {{- if $probeValues.port -}}
          {{- if kindIs "float64" $probeValues.port -}}
            {{- $_ := set (index $probeDefinition $probeHeader) "port" $probeValues.port -}}
          {{- else if kindIs "string" $probeValues.port -}}
            {{- $_ := set (index $probeDefinition $probeHeader) "port" (tpl ( $probeValues.port | toString ) $rootContext) -}}
          {{- end -}}
        {{- else if $primaryServiceDefaultPort.targetPort -}}
          {{- $_ := set (index $probeDefinition $probeHeader) "port" $primaryServiceDefaultPort.targetPort -}}
        {{- else if $primaryServiceDefaultPort.port -}}
          {{- $_ := set (index $probeDefinition $probeHeader) "port" ($primaryServiceDefaultPort.port | toString | atoi ) -}}
        {{- end -}}
      {{- end -}}

      {{- if $probeDefinition -}}
        {{- $_ := set $enabledProbes (printf "%sProbe" $probeName) $probeDefinition -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- with $enabledProbes -}}
    {{- . | toYaml -}}
  {{- end -}}
{{- end -}}
