{{/*
Returns a value from the SSO secret given a key
Usage:
{{ include "sso.get_value" (dict "key" "key-name" "context" $) }}

Params:
  - key - String - Required - Key of the value to retrieve.
  - context - Context - Required - Parent context.
*/}}
{{- define "sso.get_value" -}}
{{- $secret := (lookup "v1" "Secret" .Values.sso_config.namespace .Values.sso_config.secret_name) }}
{{- if $secret }}
  {{- $secret.data | index .key | b64dec -}}
{{- end -}}
{{- end -}}