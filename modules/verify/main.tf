resource "terraform_data" "verify_endpoints" {
  # Reejecutar verificacion cuando cambian las asociaciones objetivo.
  triggers_replace = {
    master_instance_id    = var.master_instance_id
    n8n_association_id    = var.n8n_association_id
    ollama_association_id = var.ollama_association_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      REGION="${var.aws_region}"
      INSTANCE_ID="${var.master_instance_id}"
      POLL_SECONDS=${var.command_poll_seconds}
      TIMEOUT_SECONDS=${var.command_timeout_seconds}

        START_EPOCH=$(date +%s)

      COMMAND_ID=$(aws ssm send-command \
          --region "$REGION" \
          --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --comment "verify-n8n-ollama" \
          --parameters commands="['curl -sS http://127.0.0.1/n8n/', 'curl -sS http://127.0.0.1/ollama/api/tags', 'echo Verificacion_completada']" \
        --query 'Command.CommandId' \
        --output text)

        if [ -z "$COMMAND_ID" ] || [ "$COMMAND_ID" = "None" ]; then
          echo "ERROR: no se pudo crear comando SSM"
        exit 1
      fi

        echo "Comando SSM lanzado: $COMMAND_ID"

      while true; do
          NOW_EPOCH=$(date +%s)
          ELAPSED=$((NOW_EPOCH - START_EPOCH))

          if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
            echo "ERROR: timeout esperando verificacion SSM ($${TIMEOUT_SECONDS}s)"
          aws ssm get-command-invocation \
              --region "$REGION" \
              --command-id "$COMMAND_ID" \
              --instance-id "$INSTANCE_ID" \
            --output json || true
          exit 1
        fi

          STATUS=$(aws ssm get-command-invocation \
            --region "$REGION" \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
          --query 'Status' \
          --output text 2>/dev/null || true)

          case "$STATUS" in
          Success)
              echo "✓ Verificacion SSM exitosa"

              OUTPUT=$(aws ssm get-command-invocation \
                --region "$REGION" \
                --command-id "$COMMAND_ID" \
                --instance-id "$INSTANCE_ID" \
                --query 'StandardOutputContent' \
                --output text 2>/dev/null || true)

              echo "Output del comando:"
              echo "$OUTPUT"

              if echo "$OUTPUT" | grep -q "Verificacion_completada"; then
                echo "✓ n8n y ollama respondieron correctamente"
                exit 0
              else
                echo "ERROR: endpoints no respondieron como se esperaba"
                exit 1
              fi
            ;;
            Failed|Cancelled|TimedOut|Cancelling)
            echo "ERROR: verificacion SSM fallo con estado $STATUS"
            aws ssm get-command-invocation \
                --region "$REGION" \
                --command-id "$COMMAND_ID" \
                --instance-id "$INSTANCE_ID" \
                --output json | head -n 20 || true
            exit 1
            ;;
            Pending|InProgress|Delayed|"")
              echo "Esperando verificacion SSM... estado=$${STATUS:-pendiente}"
              sleep "$POLL_SECONDS"
            ;;
          *)
              echo "Estado inesperado: $STATUS"
              sleep "$POLL_SECONDS"
            ;;
        esac
      done
    EOT
  }
}
