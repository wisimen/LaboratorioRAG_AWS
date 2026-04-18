resource "aws_ssm_association" "deploy_n8n" {
  name = "AWS-RunShellScript"

  association_name = "deploy-n8n-${replace(var.master_instance_id, "i-", "")}"

  targets {
    key    = "InstanceIds"
    values = [var.master_instance_id]
  }

  parameters = {
    commands = <<-EOT
      set -e
      cat >/tmp/n8n-deployment.yaml <<'YAML'
      ${templatefile("${path.module}/deployment.yaml", {
    namespace   = var.namespace
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
})}
      YAML

      kubectl apply -f /tmp/n8n-deployment.yaml --kubeconfig=/etc/rancher/k3s/k3s.yaml
      EOT
}
}
