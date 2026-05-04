{{/*
Validate container values
*/}}
{{- define "bjw-s.common.lib.container.validate" -}}
  {{- $rootContext := .rootContext -}}
  {{- $controllerObject := .controllerObject -}}
  {{- $containerObject := .containerObject -}}

  {{- if or (empty $containerObject.image) (not (kindIs "map" $containerObject.image)) -}}
    {{- fail (printf "Container '%s': Image must be a dictionary with repository and tag fields. Define the image properly under 'controllers.%s.containers.%s.image'." $containerObject.identifier $controllerObject.identifier $containerObject.identifier) }}
  {{- end -}}

  {{- if empty (dig "image" "repository" nil $containerObject) -}}
    {{- fail (printf "Container '%s': Image repository is required. Specify the repository under 'controllers.%s.containers.%s.image.repository'." $containerObject.identifier $controllerObject.identifier $containerObject.identifier) }}
  {{- end -}}

  {{- if and (empty (dig "image" "tag" nil $containerObject)) (empty (dig "image" "digest" nil $containerObject)) -}}
    {{- fail (printf "Container '%s': Either image tag or digest is required. Specify a tag or digest under 'controllers.%s.containers.%s.image'." $containerObject.identifier $controllerObject.identifier $containerObject.identifier) }}
  {{- end -}}
{{- end -}}
