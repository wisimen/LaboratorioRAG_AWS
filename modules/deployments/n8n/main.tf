resource "aws_ssm_association" "deploy_n8n" {
  name = "AWS-RunShellScript"

  association_name = "deploy-n8n-${replace(var.master_instance_id, "i-", "")}"

  targets {
    key    = "InstanceIds"
    values = [var.master_instance_id]
  }

  parameters = {
    commands = <<-EOT
      set -euo pipefail

      KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"

      wait_for_k3s_api() {
        local max_retries=30
        local sleep_seconds=10
        local attempt=1

        until sudo kubectl --kubeconfig="$KUBECONFIG_PATH" get --raw='/readyz' >/dev/null 2>&1; do
          if [ "$attempt" -ge "$max_retries" ]; then
            echo "ERROR: API de K3S no estuvo lista tras $${max_retries} intentos"
            sudo systemctl status k3s --no-pager || true
            sudo journalctl -u k3s -n 100 --no-pager || true
            return 1
          fi
          echo "Esperando API de K3S... intento $${attempt}/$${max_retries}"
          attempt=$((attempt + 1))
          sleep "$sleep_seconds"
        done
      }

      apply_with_retry() {
        local file_path="$1"
        local max_retries=12
        local sleep_seconds=10
        local attempt=1

        until sudo kubectl apply -f "$file_path" --kubeconfig="$KUBECONFIG_PATH" >/tmp/n8n-kubectl.log 2>&1; do
          if [ "$attempt" -ge "$max_retries" ]; then
            echo "ERROR: kubectl apply falló tras $${max_retries} intentos"
            cat /tmp/n8n-kubectl.log || true
            return 1
          fi
          echo "kubectl apply falló, reintentando... intento $${attempt}/$${max_retries}"
          cat /tmp/n8n-kubectl.log || true
          attempt=$((attempt + 1))
          sleep "$sleep_seconds"
        done

        cat /tmp/n8n-kubectl.log || true
      }

cat >/tmp/n8n-deployment.yaml <<'YAML'
${templatefile("${path.module}/deployment.yaml", {
    namespace   = var.namespace
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    })}
---
${templatefile("${path.module}/service.yaml", {
    namespace = var.namespace
    })}
---
${templatefile("${path.module}/middleware.yaml", {
  namespace = var.namespace
})}
---
${templatefile("${path.module}/ingress.yaml", {
    namespace = var.namespace
})}
YAML

wait_for_k3s_api
apply_with_retry /tmp/n8n-deployment.yaml
      EOT
}
}
