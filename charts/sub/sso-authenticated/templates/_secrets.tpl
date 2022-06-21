{{/*
Returns a value from the SSO secret given a key
Usage:
{{ include "sso.get_value" (dict "key" "key-name" "context" $) }}

Params:
  - key - String - Required - Key of the value to retrieve.
  - context - Context - Required - Parent context.
*/}}
{{- define "sso.get_value" -}}
  {{- $secret := (lookup "v1" "Secret" .context.Values.sso_config.namespace .context.Values.sso_config.secret_name) }}
  {{- if $secret }}
    {{- if hasKey $secret.data .key }}
      {{- index $secret.data .key -}}
    {{- else }}
      {{- printf "\nERROR: The SSO secret does not contain the key \"%s\"\n" .key | fail -}}
    {{- end -}}
  {{- else }}
    {{- printf "\nERROR: The SSO secret \"%s\" does not exist in namespace \"%s\"\n" .context.Values.sso_config.secret_name .context.Values.sso_config.namespace | fail -}}
  {{- end -}}
{{- end -}}