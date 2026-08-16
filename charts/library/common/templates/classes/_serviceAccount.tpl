{{/*
This template serves as a blueprint for ServiceAccount objects that are created
using the common library.
*/}}
{{- define "bjw-s.common.class.serviceAccount" -}}
  {{- $rootContext := .rootContext -}}
  {{- $serviceAccountObject := .object -}}

  {{- $labels := merge
    ($serviceAccountObject.labels | default dict)
    (include "bjw-s.common.lib.metadata.allLabels" $rootContext | fromYaml)
  -}}
  {{- $annotations := merge
    ($serviceAccountObject.annotations | default dict)
    (include "bjw-s.common.lib.metadata.globalAnnotations" $rootContext | fromYaml)
  -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $serviceAccountObject.name }}
  {{- with $labels }}
  labels:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with $annotations }}
  annotations:
    {{- range $key, $value := . }}
      {{- printf "%s: %s" $key (tpl $value $rootContext | toYaml ) | nindent 4 }}
    {{- end }}
  {{- end }}
  namespace: {{ $rootContext.Release.Namespace }}
{{- if hasKey $serviceAccountObject "automountServiceAccountToken" }}
automountServiceAccountToken: {{ $serviceAccountObject.automountServiceAccountToken }}
{{- end }}
{{- if $serviceAccountObject.staticToken }}
secrets:
  - name: {{ get (include "bjw-s.common.lib.secret.getByIdentifier" (dict "rootContext" $rootContext "id" (printf "%s-sa-token" $serviceAccountObject.identifier) ) | fromYaml) "name"}}
{{- end }}
{{- end -}}
