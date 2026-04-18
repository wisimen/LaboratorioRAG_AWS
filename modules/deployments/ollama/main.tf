resource "aws_ssm_association" "deploy_ollama" {
  name = "AWS-RunShellScript"

  association_name = "deploy-ollama-${replace(var.master_instance_id, "i-", "")}"

  targets {
    key    = "InstanceIds"
    values = [var.master_instance_id]
  }

  parameters = {
    commands = <<-EOT
      set -e
      cat >/tmp/ollama-deployment.yaml <<'YAML'
      ${templatefile("${path.module}/deployment.yaml", {
    namespace = var.namespace
})}
      YAML

      kubectl apply -f /tmp/ollama-deployment.yaml --kubeconfig=/etc/rancher/k3s/k3s.yaml
      EOT
}
}
