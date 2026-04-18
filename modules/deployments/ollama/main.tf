resource "aws_ssm_association" "deploy_ollama" {
  name = "AWS-RunShellScript"

  association_name = "deploy-ollama-${replace(var.master_instance_id, "i-", "")}"

  targets {
    key    = "InstanceIds"
    values = [var.master_instance_id]
  }

  parameters = {
    commands = [
      <<-EOT
      set -e
      cat >/tmp/ollama-deployment.yaml <<'YAML'
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: ollama
        namespace: ${var.namespace}
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: ollama
        template:
          metadata:
            labels:
              app: ollama
          spec:
            containers:
              - name: ollama
                image: ollama/ollama:latest
                imagePullPolicy: IfNotPresent
                ports:
                  - containerPort: 11434
                volumeMounts:
                  - name: ollama-data
                    mountPath: /root/.ollama
            volumes:
              - name: ollama-data
                persistentVolumeClaim:
                  claimName: efs-pvc-shared
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: ollama
        namespace: ${var.namespace}
      spec:
        type: ClusterIP
        selector:
          app: ollama
        ports:
          - name: http
            port: 11434
            targetPort: 11434
      ---
      apiVersion: traefik.containo.us/v1alpha1
      kind: Middleware
      metadata:
        name: ollama-stripprefix
        namespace: ${var.namespace}
      spec:
        stripPrefix:
          prefixes:
            - /ollama
      ---
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: ollama
        namespace: ${var.namespace}
        annotations:
          traefik.ingress.kubernetes.io/router.middlewares: ${var.namespace}-ollama-stripprefix@kubernetescrd
      spec:
        ingressClassName: traefik
        rules:
          - http:
              paths:
                - path: /ollama
                  pathType: Prefix
                  backend:
                    service:
                      name: ollama
                      port:
                        number: 11434
      YAML

      kubectl apply -f /tmp/ollama-deployment.yaml --kubeconfig=/etc/rancher/k3s/k3s.yaml
      EOT
    ]
  }
}
