########## Security Group - Cluster K3S ##########
# / -> VPC -> Security Group -> K3S
# Los nodos están en una subnet PRIVADA; el acceso de administración se realiza
# exclusivamente a través de SSM Session Manager — no hay SSH abierto.

resource "aws_security_group" "sg-k3s" {
  name        = "sg-k3s-${var.environment}"
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

  # Todo el tráfico saliente permitido (necesario para NAT → internet y VPC Endpoints)
  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-k3s-${var.environment}"
    Environment = var.environment
  }
}


########## Security Group - VPC Endpoints SSM ##########
# Permite tráfico HTTPS desde los nodos K3S hacia los VPC Interface Endpoints de SSM

resource "aws_security_group" "sg-ssm-endpoints" {
  name        = "sg-ssm-endpoints-k3s-${var.environment}"
  description = "Security Group para los VPC Endpoints de SSM del cluster K3S"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS desde nodos K3S hacia VPC Endpoints SSM"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-k3s.id]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-ssm-endpoints-k3s-${var.environment}"
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
  security_group_ids  = [aws_security_group.sg-ssm-endpoints.id]
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
  security_group_ids  = [aws_security_group.sg-ssm-endpoints.id]
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
  security_group_ids  = [aws_security_group.sg-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ec2messages-k3s-${var.environment}"
    Environment = var.environment
  }
}


########## IAM Role para nodos K3S ##########
# Permite a las instancias acceder a SSM Parameter Store y S3

resource "aws_iam_role" "k3s-role" {
  name = "k3s-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "k3s-role-${var.environment}"
    Environment = var.environment
  }
}

# Permite el uso de SSM Session Manager y acceso básico a SSM
resource "aws_iam_role_policy_attachment" "k3s-ssm-core" {
  role       = aws_iam_role.k3s-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Permite leer/escribir parámetros en SSM Parameter Store (token de unión al cluster)
resource "aws_iam_role_policy" "k3s-ssm-params" {
  name = "k3s-ssm-params-${var.environment}"
  role = aws_iam_role.k3s-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:DeleteParameter"
      ]
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/k3s/${var.environment}/*"
    }]
  })
}

# Permite a los nodos leer y escribir únicamente en el bucket S3 del cluster K3S
resource "aws_iam_role_policy" "k3s-s3" {
  name = "k3s-s3-policy-${var.environment}"
  role = aws_iam_role.k3s-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::k3s-storage-${var.environment}-${data.aws_caller_identity.current.account_id}",
        "arn:aws:s3:::k3s-storage-${var.environment}-${data.aws_caller_identity.current.account_id}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "k3s-profile" {
  name = "k3s-profile-${var.environment}"
  role = aws_iam_role.k3s-role.name
}


########## EC2 K3S Master ##########
# / -> VPC -> Subnet -> EC2 (Master)
# Instala k3s en modo servidor y publica el token de unión en SSM

resource "aws_instance" "k3s-master" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.sg-k3s.id]
  iam_instance_profile        = aws_iam_instance_profile.k3s-profile.name
  associate_public_ip_address = false # Subnet privada — sin IP pública

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Instalar k3s como servidor (Master) — versión fijada para reproducibilidad
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="${var.k3s_version}" \
      sh -s - server \
      --write-kubeconfig-mode=644 \
      --disable=traefik

    # Esperar a que k3s esté completamente listo antes de leer el token (máx. 5 min)
    echo "Esperando a que el servicio k3s esté activo..."
    K3S_WAIT=0
    until systemctl is-active --quiet k3s && kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml 2>/dev/null; do
      K3S_WAIT=$((K3S_WAIT + 10))
      if [ $K3S_WAIT -ge 300 ]; then
        echo "ERROR: k3s no estuvo listo en 5 minutos, abortando."
        exit 1
      fi
      echo "k3s aún no está listo, reintentando en 10s... ($K3S_WAIT/300s)"
      sleep 10
    done
    echo "k3s está listo."

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
  vpc_security_group_ids      = [aws_security_group.sg-k3s.id]
  iam_instance_profile        = aws_iam_instance_profile.k3s-profile.name
  associate_public_ip_address = false # Subnet privada — sin IP pública

  user_data = <<-EOF
    #!/bin/bash
    set -e

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
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="${var.k3s_version}" \
      K3S_URL="https://$MASTER_IP:6443" \
      K3S_TOKEN="$K3S_TOKEN" \
      sh -
  EOF

  # El Worker debe crearse después del Master para que el token ya esté en SSM
  depends_on = [aws_instance.k3s-master]

  tags = {
    Name        = "k3s-worker-${var.environment}"
    Environment = var.environment
    Role        = "worker"
  }
}
