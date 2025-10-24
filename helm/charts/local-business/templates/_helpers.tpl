###
## Service
###
# Specify the load balancer scheme as internet-facing to create a public-facing Network Load Balancer (NLB)
{{- define "service.metadata.annotations.lb" -}}
{{- if eq .Values.environment "aws" -}}
service.beta.kubernetes.io/aws-load-balancer-type: nlb
service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: deregistration_delay.timeout_seconds=30
{{- if .Values.service.internalLB }}
service.beta.kubernetes.io/aws-load-balancer-scheme: internal
{{- else }}
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
{{- end }}
{{- end -}}
{{- end -}}

# Specify security groups for a service
{{- define "service.metadata.annotations.sg" -}}
{{- if eq .Values.environment "aws" -}}
{{- $raw := (.Files.Get ".sg-ids.output" | default "") | trim -}}
{{- if $raw -}}
  {{- $clean := $raw
      | replace "[" ""
      | replace "]" ""
      | replace "\"" ""
      | replace " " ""
      | replace "\n" ""
      | replace "\r" "" -}}
  {{- $items := splitList "," $clean -}}
service.beta.kubernetes.io/aws-load-balancer-security-groups: "{{ join "," $items }}"
{{- end -}}
{{- end -}}
{{- end -}}


###
## Ingress
###
# Specify ingress annotations
{{- define "app.ingress.annotations" -}}
{{- if and .Values.ingress (eq .Values.environment "local") -}}
kubernetes.io/ingress.class: nginx
{{- else if and .Values.ingress (eq .Values.environment "aws") -}}
kubernetes.io/ingress.class: alb
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
alb.ingress.kubernetes.io/healthcheck-path: /health
{{- end -}}
{{- end -}}

{{- define "app.ingress.ingressClassName" -}}
{{- if and .Values.ingress (eq .Values.environment "local") -}}
nginx
{{- else if and .Values.ingress (eq .Values.environment "aws") -}}
alb
{{- end -}}
{{- end -}}