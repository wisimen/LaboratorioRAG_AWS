########## Security Group - Cluster K3S ##########
# / -> VPC -> Security Group -> K3S
# Los nodos están en una subnet PRIVADA; el acceso de administración se realiza
# exclusivamente a través de SSM Session Manager — no hay SSH abierto.

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}


########## Security Group - VPC Endpoints SSM ##########
# Permite tráfico HTTPS desde los nodos K3S hacia los VPC Interface Endpoints de SSM

########## EC2 K3S Master ##########
# / -> VPC -> Subnet -> EC2 (Master)
# Instala k3s en modo servidor y publica el token de unión en SSM

resource "aws_instance" "k3s-master" {
  ami                         = var.ami_id
  instance_type               = "t3.small"
  subnet_id                   = var.master_subnet_id
  vpc_security_group_ids      = [var.k3s_security_group_id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = true # Subnet publica — con IP pública

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Instalar k3s como servidor (Master) — versión fijada para reproducibilidad
    INSTALLER=/tmp/install-k3s.sh
    curl -sfL --retry 6 --retry-delay 5 --retry-all-errors https://get.k3s.io -o "$INSTALLER"
    chmod +x "$INSTALLER"
    INSTALL_K3S_VERSION="${var.k3s_version}" \
      sh "$INSTALLER" server \
      --write-kubeconfig-mode=644
    rm -f "$INSTALLER"

    # Esperar a que k3s esté completamente listo antes de leer el token (máx. 5 min)
    echo "Esperando a que el servicio k3s esté activo..."
    K3S_WAIT=0
    until systemctl is-active --quiet k3s && kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml 2>/dev/null; do
      K3S_WAIT=$((K3S_WAIT + 10))
      if [ $K3S_WAIT -ge 300 ]; then
        echo "ERROR: k3s no estuvo listo en 5 minutos, abortando."
        systemctl status k3s --no-pager || true
        journalctl -u k3s -n 100 --no-pager || true
        exit 1
      fi
      echo "k3s aún no está listo, reintentando en 10s... ($K3S_WAIT/300s)"
      sleep 10
    done
    echo "k3s está listo."

    # Instalar Helm y desplegar el driver CSI de EFS dentro de kube-system.
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
    helm repo update
    helm upgrade --install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
      --namespace kube-system \
      --wait \
      --timeout 10m

    # Crear PV/PVC base para cargas que usarán almacenamiento compartido (ollama/n8n).
    cat >/tmp/k3s-efs-pv-pvc.yaml <<EOM
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: efs-pv-shared
    spec:
      capacity:
        storage: 30Gi
      volumeMode: Filesystem
      accessModes:
        - ReadWriteMany
      persistentVolumeReclaimPolicy: Retain
      storageClassName: ""
      csi:
        driver: efs.csi.aws.com
        volumeHandle: ${var.efs_id}
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: efs-pvc-shared
      namespace: default
    spec:
      accessModes:
        - ReadWriteMany
      storageClassName: ""
      resources:
        requests:
          storage: 30Gi
      volumeName: efs-pv-shared
    EOM

    kubectl apply -f /tmp/k3s-efs-pv-pvc.yaml --kubeconfig=/etc/rancher/k3s/k3s.yaml

    # Publicar el token de unión en SSM para que el Worker pueda recuperarlo
    K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    aws ssm put-parameter \
      --region ${var.aws_region} \
      --name "/k3s/${var.environment}/node-token" \
      --value "$K3S_TOKEN" \
      --type "SecureString" \
      --overwrite

    # Publicar la IP privada del Master en SSM
    MASTER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    aws ssm put-parameter \
      --region ${var.aws_region} \
      --name "/k3s/${var.environment}/master-ip" \
      --value "$MASTER_IP" \
      --type "String" \
      --overwrite
  EOF

  tags = {
    Name        = "k3s-master-${var.environment}"
    Environment = var.environment
    Role        = "master"
  }
}


########## EC2 K3S Worker ##########
# / -> VPC -> Subnet -> EC2 (Worker)
# Recupera el token del Master desde SSM e instala k3s en modo agente

resource "aws_instance" "k3s-worker" {
  ami                         = var.ami_id
  instance_type               = "t3.small"
  subnet_id                   = var.worker_subnet_id
  vpc_security_group_ids      = [var.k3s_security_group_id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = false # Subnet privada — sin IP pública

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Esperar a que el Master publique el token en SSM Parameter Store
    MAX_RETRIES=30
    RETRY=0
    while true; do
      TOKEN=$(aws ssm get-parameter \
        --region ${var.aws_region} \
        --name "/k3s/${var.environment}/node-token" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text 2>/tmp/ssm-error.log) && break
      RETRY=$((RETRY + 1))
      echo "Esperando token del Master... intento $RETRY de $MAX_RETRIES"
      cat /tmp/ssm-error.log || true
      if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "ERROR: No se pudo obtener el token del Master tras $MAX_RETRIES intentos"
        exit 1
      fi
      sleep 20
    done

    # Obtener la IP del Master desde SSM
    K3S_TOKEN="$TOKEN"
    MASTER_IP=$(aws ssm get-parameter \
      --region ${var.aws_region} \
      --name "/k3s/${var.environment}/master-ip" \
      --query "Parameter.Value" \
      --output text)

    # Instalar k3s en modo agente (Worker) — versión fijada para reproducibilidad
    INSTALLER=/tmp/install-k3s.sh
    curl -sfL --retry 6 --retry-delay 5 --retry-all-errors https://get.k3s.io -o "$INSTALLER"
    chmod +x "$INSTALLER"
    INSTALL_K3S_VERSION="${var.k3s_version}" \
      K3S_URL="https://$MASTER_IP:6443" \
      K3S_TOKEN="$K3S_TOKEN" \
      sh "$INSTALLER"
    rm -f "$INSTALLER"
  EOF

  # El Worker debe crearse después del Master para que el token ya esté en SSM
  depends_on = [aws_instance.k3s-master]

  tags = {
    Name        = "k3s-worker-${var.environment}"
    Environment = var.environment
    Role        = "worker"
  }
}

resource "aws_ssm_association" "apply_efs_shared_pv" {
  name = "AWS-RunShellScript"

  association_name = "k3s-efs-pv-${replace(aws_instance.k3s-master.id, "i-", "")}" 

  targets {
    key    = "InstanceIds"
    values = [aws_instance.k3s-master.id]
  }

  parameters = {
    commands = <<-EOT
      set -euo pipefail

      KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
      TARGET_EFS_ID="${var.efs_id}"

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
          attempt=$((attempt + 1))
          sleep "$sleep_seconds"
        done
      }

      wait_for_k3s_api

      CURRENT_HANDLE=$(sudo kubectl get pv efs-pv-shared --kubeconfig="$KUBECONFIG_PATH" -o jsonpath='{.spec.csi.volumeHandle}' 2>/dev/null || true)

      # Si el PV apunta a otro filesystem, liberamos PVC/PV para recrearlo con el EFS actual.
      if [ -n "$CURRENT_HANDLE" ] && [ "$CURRENT_HANDLE" != "$TARGET_EFS_ID" ]; then
        sudo kubectl -n default scale deployment/ollama --replicas=0 --kubeconfig="$KUBECONFIG_PATH" >/dev/null 2>&1 || true
        sudo kubectl delete pvc efs-pvc-shared -n default --ignore-not-found=true --kubeconfig="$KUBECONFIG_PATH"
        sudo kubectl delete pv efs-pv-shared --ignore-not-found=true --kubeconfig="$KUBECONFIG_PATH"
      fi

      cat >/tmp/k3s-efs-pv-pvc.yaml <<YAML
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: efs-pv-shared
      spec:
        capacity:
          storage: 30Gi
        volumeMode: Filesystem
        accessModes:
          - ReadWriteMany
        persistentVolumeReclaimPolicy: Retain
        storageClassName: ""
        csi:
          driver: efs.csi.aws.com
          volumeHandle: ${var.efs_id}
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: efs-pvc-shared
        namespace: default
      spec:
        accessModes:
          - ReadWriteMany
        storageClassName: ""
        resources:
          requests:
            storage: 30Gi
        volumeName: efs-pv-shared
      YAML

      sudo kubectl apply -f /tmp/k3s-efs-pv-pvc.yaml --kubeconfig="$KUBECONFIG_PATH"

      # Si ollama existe, lo reactivamos tras reconciliar el PVC.
      sudo kubectl -n default scale deployment/ollama --replicas=1 --kubeconfig="$KUBECONFIG_PATH" >/dev/null 2>&1 || true
    EOT
  }

  depends_on = [aws_instance.k3s-master]
}
