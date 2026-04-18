resource "aws_ssm_association" "deploy_n8n" {
  name = "AWS-RunShellScript"

  association_name = "deploy-n8n-${replace(var.master_instance_id, "i-", "")}"

  targets {
    key    = "InstanceIds"
    values = [var.master_instance_id]
  }

  parameters = {
    commands = [
      <<-EOT
      set -e
      cat >/tmp/n8n-deployment.yaml <<'YAML'
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: n8n
        namespace: ${var.namespace}
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: n8n
        template:
          metadata:
            labels:
              app: n8n
          spec:
            containers:
              - name: n8n
                image: n8nio/n8n:latest
                imagePullPolicy: IfNotPresent
                ports:
                  - containerPort: 5678
                env:
                  - name: DB_TYPE
                    value: postgresdb
                  - name: DB_POSTGRESDB_HOST
                    value: "${var.db_host}"
                  - name: DB_POSTGRESDB_PORT
                    value: "5432"
                  - name: DB_POSTGRESDB_DATABASE
                    value: "${var.db_name}"
                  - name: DB_POSTGRESDB_USER
                    value: "${var.db_user}"
                  - name: DB_POSTGRESDB_PASSWORD
                    value: "${var.db_password}"
                  - name: N8N_PATH
                    value: "/n8n/"
                  - name: N8N_EDITOR_BASE_URL
                    value: "/n8n/"
                  - name: N8N_PORT
                    value: "5678"
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: n8n
        namespace: ${var.namespace}
      spec:
        type: ClusterIP
        selector:
          app: n8n
        ports:
          - name: http
            port: 5678
            targetPort: 5678
      ---
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: n8n
        namespace: ${var.namespace}
      spec:
        ingressClassName: traefik
        rules:
          - http:
              paths:
                - path: /n8n
                  pathType: Prefix
                  backend:
                    service:
                      name: n8n
                      port:
                        number: 5678
      YAML

      kubectl apply -f /tmp/n8n-deployment.yaml --kubeconfig=/etc/rancher/k3s/k3s.yaml
      EOT
    ]
  }
}
