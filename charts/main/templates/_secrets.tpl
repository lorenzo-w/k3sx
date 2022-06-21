{{/*
Generate secret password or retrieve one if already created.

Usage:
{{ include "k3sx.secrets.retrieve" (dict "secret" "secret-name" "key" "keyName" "providedValues" (list "path.to.password1" "path.to.password2") "namespace" "my-namespace" "length" 10 "strong" false "chartName" "chartName" "context" $) }}

Params:
  - secret - String - Required - Name of the 'Secret' resource where the password is stored.
  - key - String - Required - Name of the key in the secret.
  - providedValues - List<String> - Required - The path to the validating value in the values.yaml, e.g: "mysql.password". Will pick first parameter with a defined value.
  - namespace - String - Required - Namespace of the secret.
  - length - int - Optional - Length of the generated random password.
  - strong - Boolean - Optional - Whether to add symbols to the generated random password.
  - chartName - String - Optional - Name of the chart used when said chart is deployed as a subchart.
  - context - Context - Required - Parent context.

The order in which this function returns a secret password:
  1. Already existing 'Secret' resource
     (If a 'Secret' resource is found under the name provided to the 'secret' parameter to this function and that 'Secret' resource contains a key with the name passed as the 'key' parameter to this function then the value of this existing secret password will be returned)
  2. Password provided via the values.yaml
     (If one of the keys passed to the 'providedValues' parameter to this function is a valid path to a key in the values.yaml and has a value, the value of the first key with a value will be returned)
  3. Randomly generated secret password
     (A new random secret password with the length specified in the 'length' parameter will be generated and returned)

*/}}
{{- define "k3sx.secrets.retrieve" -}}

{{- $password := "" }}
{{- $subchart := "" }}
{{- $chartName := default "" .chartName }}
{{- $passwordLength := default 10 .length }}
{{- $providedPasswordKey := include "common.utils.getKeyFromList" (dict "keys" .providedValues "context" $.context) }}
{{- $providedPasswordValue := include "common.utils.getValueFromKey" (dict "key" $providedPasswordKey "context" $.context) }}
{{- $secretData := (lookup "v1" "Secret" .namespace .secret).data }}
{{- if $secretData }}
  {{- if hasKey $secretData .key }}
    {{- $password = index $secretData .key }}
  {{- else }}
    {{- printf "\nPASSWORDS ERROR: The secret \"%s\" does not contain the key \"%s\"\n" .secret .key | fail -}}
  {{- end -}}
{{- else if $providedPasswordValue }}
  {{- $password = $providedPasswordValue | toString | b64enc | quote }}
{{- else }}

  {{- if .context.Values.enabled }}
    {{- $subchart = $chartName }}
  {{- end -}}

  {{- $requiredPassword := dict "valueKey" $providedPasswordKey "secret" .secret "field" .key "subchart" $subchart "context" $.context -}}
  {{- $requiredPasswordError := include "common.validations.values.single.empty" $requiredPassword -}}
  {{- $passwordValidationErrors := list $requiredPasswordError -}}
  {{- include "common.errors.upgrade.passwords.empty" (dict "validationErrors" $passwordValidationErrors "context" $.context) -}}

  {{- if .strong }}
    {{- $subStr := list (lower (randAlpha 1)) (randNumeric 1) (upper (randAlpha 1)) | join "_" }}
    {{- $password = randAscii $passwordLength }}
    {{- $password = regexReplaceAllLiteral "\\W" $password "@" | substr 5 $passwordLength }}
    {{- $password = printf "%s%s" $subStr $password | toString | shuffle | b64enc | quote }}
  {{- else }}
    {{- $password = randAlphaNum $passwordLength | b64enc | quote }}
  {{- end }}
{{- end -}}
{{- printf "%s" $password -}}
{{- end -}}