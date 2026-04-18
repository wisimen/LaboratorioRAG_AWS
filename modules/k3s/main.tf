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

resource "aws_security_group" "secgroup-cluster-k3s" {
  description = "Security Group para los nodos del cluster K3S (red privada, sin SSH)"
  vpc_id      = var.vpc_id

  # API Server de Kubernetes (solo desde dentro de la VPC)
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Flannel VXLAN (overlay network entre nodos)
  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Métricas de Kubelet
  ingress {
    description = "Kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort services (solo desde dentro de la VPC)
  ingress {
    description = "NodePort Services (interno VPC)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Ingress HTTP para acceso por path (/n8n, /ollama) dentro de la VPC
  ingress {
    description = "Ingress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Ingress HTTPS para acceso por path (/n8n, /ollama) dentro de la VPC
  ingress {
    description = "Ingress HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Todo el tráfico saliente permitido (necesario para NAT → internet y VPC Endpoints)
  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "secgroup-cluster-k3s-${var.environment}"
    Environment = var.environment
  }
}


########## Security Group - VPC Endpoints SSM ##########
# Permite tráfico HTTPS desde los nodos K3S hacia los VPC Interface Endpoints de SSM

resource "aws_security_group" "secgroup-k3s-ssm-endpoints" {
  description = "Security Group para los VPC Endpoints de SSM del cluster K3S"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS desde nodos K3S hacia VPC Endpoints SSM"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.secgroup-cluster-k3s.id]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "secgroup-k3s-ssm-endpoints-${var.environment}"
    Environment = var.environment
  }
}


########## VPC Interface Endpoints - SSM Session Manager ##########
# Permiten que las instancias en la subnet PRIVADA se comuniquen con SSM, SSM Session
# Manager y EC2 Messages sin necesidad de salir a internet a través del NAT Gateway.

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ssm-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ssmmessages-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ec2messages-k3s-${var.environment}"
    Environment = var.environment
  }
}


########## EC2 K3S Master ##########
# / -> VPC -> Subnet -> EC2 (Master)
# Instala k3s en modo servidor y publica el token de unión en SSM

resource "aws_instance" "k3s-master" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.secgroup-cluster-k3s.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = false # Subnet privada — sin IP pública

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
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.secgroup-cluster-k3s.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = false # Subnet privada — sin IP pública

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
