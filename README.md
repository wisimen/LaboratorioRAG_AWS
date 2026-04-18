# LaboratorioRAG_AWS

Infraestructura modular en AWS con Terraform para desplegar un clúster K3S en ambiente privado con almacenamiento compartido optimizado para costos.

---

## Arquitectura - Módulos

La infraestructura se organiza en 5 módulos independientes reutilizables:

### 📡 **Módulo: Networking**
Proporciona la base de red segura para toda la infraestructura.

**Componentes:**
- **VPC**: Red virtual con CIDR configurable
- **Subnets**: 4 subnets (2 públicas, 2 privadas) distribuidas en 2 AZs para alta disponibilidad
- **IGW + NAT Gateway**: Para comunicación entrante (IGW) y salida desde redes privadas (NAT)
- **Route Tables**: Enrutamiento público y privado con separación de tráfico
- **Network ACLs**: Control de acceso a nivel de subnet
- **Security Groups**:
  - `secgroup-public-frontend`: Tráfico HTTP/HTTPS público
  - `secgroup-cluster-k3s`: Comunicación intra-cluster (solo dentro de VPC)
  - `secgroup-k3s-ssm-endpoints`: Para VPC Interface Endpoints de SSM
  - `efs_sg`: NFS (puerto 2049) desde toda la VPC - **crítico para almacenamiento**

**VPC Endpoints (sin NAT Gateway):**
- SSM Session Manager para administración remota
- SSM Messages para comunicación con agentes
- EC2 Messages para integración EC2

**Recursos para Base de Datos (RDS):**
- `rds_sg`: PostgreSQL (puerto 5432) abierto dentro de la VPC
- `rds_subnet_group`: usa subnets privadas para desplegar RDS sin exposición pública

---

### 🖥️ **Módulo: EC2**
Instancia frontend web pública para acceso de usuarios.

**Características:**
- **AMI**: Amazon Linux 2023 (actualizada automáticamente)
- **Instancia**: t2.small en subnet pública frontend
- **IP Pública**: Asignada automáticamente
- **Acceso**: SSH directo desde internet (puerto 22)
- **Caso de uso**: Servidor web, proxy inverso, dashboard de monitoreo

**Outputs:**
- IP pública
- URL de acceso (http://)

---

### 💾 **Módulo: Storage**
EFS One Zone optimizado para bajo costo - perfecto para Ollama, n8n y datos compartidos.

**Características de Bajo Costo:**
- ✅ **One Zone**: Sin replicación multi-AZ (ahorro ~40%)
- ✅ **Sin Backups**: Política de backup deshabilitada
- ✅ **30Gi de Capacidad**: Suficiente para Ollama + n8n + datos iniciales
- ✅ **Transition a IA**: Datos inactivos migran automáticamente a Infrequent Access después de 30 días
- ✅ **Encriptación**: Habilitada por defecto
- ✅ **Throughput**: Modo Bursting (económico, automático)

**Detalles Técnicos:**
- **Mount Target**: En subnet privada backend para máxima seguridad
- **Security Group**: NFS (2049) restringido a CIDR de VPC
- **Integración K3S**: CSI Driver `efs.csi.aws.com` instalado automáticamente

**Outputs:**
- ID del EFS (para K3S)
- DNS del EFS

---

### 🗄️ **Módulo: RDS (PostgreSQL para n8n)**
Base de datos relacional administrada para persistencia de workflows, credenciales y estado de n8n.

**Objetivo:**
- Proveer una base de datos PostgreSQL privada, segura y parametrizable por entorno (`default`, `dev`, `test`, `prod`).

**Parámetros del módulo (totalmente variables):**
- `engine` (default: `postgres`)
- `engine_version` (default: `17.6`)
- `instance_class`
- `allocated_storage`
- `db_name`
- `username`
- `password`
- `db_subnet_group_name`
- `vpc_security_group_ids`
- `skip_final_snapshot`

**Características implementadas:**
- ✅ RDS privado (`publicly_accessible = false`)
- ✅ Despliegue en subnets privadas mediante `db_subnet_group_name`
- ✅ Security Group con acceso PostgreSQL por puerto `5432`
- ✅ Integración con K3S para consumo desde workloads internos
- ✅ Encriptación de almacenamiento habilitada

**Dónde se definen los defaults:**
- En `variables.tf` con valores por workspace.

**Outputs:**
- Endpoint de conexión (`host:port`)
- Host
- Puerto
- Nombre de base de datos
- Usuario
- Connection string para n8n (sensible)

### Ejemplo de configuración por entornos (RDS)

El proyecto ya define valores por entorno en `variables.tf` usando mapas indexados por `terraform.workspace`.

Referencia rápida de defaults:

- `default`:
  - `rds_engine = postgres`
  - `rds_engine_version = 17.6`
  - `rds_instance_class = db.t4g.micro`
  - `rds_allocated_storage = 20`
  - `rds_skip_final_snapshot = true`
- `dev`:
  - `rds_engine = postgres`
  - `rds_engine_version = 17.6`
  - `rds_instance_class = db.t4g.micro`
  - `rds_allocated_storage = 20`
  - `rds_skip_final_snapshot = true`
- `test`:
  - `rds_engine = postgres`
  - `rds_engine_version = 17.6`
  - `rds_instance_class = db.t4g.micro`
  - `rds_allocated_storage = 20`
  - `rds_skip_final_snapshot = true`
- `prod`:
  - `rds_engine = postgres`
  - `rds_engine_version = 17.6`
  - `rds_instance_class = db.t4g.small`
  - `rds_allocated_storage = 100`
  - `rds_skip_final_snapshot = false`

Si necesitas overrides puntuales, puedes usar un archivo `.tfvars` por entorno y aplicar así:

```bash
terraform workspace select dev
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

Ejemplo mínimo de `env/dev.tfvars`:

```hcl
rds_password = {
  dev = "CambiaEstePasswordDev!"
}
```

Recomendación para secretos:
- No subir passwords reales al repositorio.
- Preferir inyectar `rds_password` con variables de entorno (`TF_VAR_rds_password`) o desde un sistema de secretos en CI/CD.

---

### ☸️ **Módulo: K3S (Kubernetes Ligero)**
Clúster Kubernetes optimizado para recursos limitados - ejecuta Ollama, n8n y aplicaciones Cloud-Native.

**Arquitectura:**
- **Master**: Nodo servidor K3S con etcd integrado
- **Worker**: Nodo agente para cargas de trabajo
- **Ubicación**: Subnet privada backend (sin IPs públicas)
- **Acceso**: Solo vía AWS SSM Session Manager (sin SSH abierto)

**Auto-Instalación:**
- ✅ K3S Server (v1.x latest)
- ✅ AWS EFS CSI Driver vía Helm (para montar EFS)
- ✅ PersistentVolume `efs-pv-shared` (30Gi, ReadWriteMany)
- ✅ PersistentVolumeClaim `efs-pvc-shared` reservado para aplicaciones

**Características de Seguridad:**
- Comunicación Kubernetes (6443) solo dentro de VPC
- Flannel VXLAN para overlay network
- Kubelet metrics internos (10250)
- NodePort services limitados a VPC (30000-32767)

**Outputs:**
- Instance IDs (para SSM Session Manager)
- Token de unión guardado en AWS SSM Parameter Store
- IP privada del Master (redundancia)

---

## Flujo de Despliegue

```
Networking (VPC + Security Groups)
    ↓
EC2 (Frontend Público)
    ↓
Storage (EFS One Zone)
    ↓
RDS (PostgreSQL Privado para n8n)
  ↓
K3S (Master + Worker con Almacenamiento Persistente)
```

---

## Lista de comandos

1. Añadir configuracion
`aws configure`
Necesita variables 
```
[default] #->Perfil 1
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...


[Perfil2] #->Perfil 2
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

_`json` como salida por defecto_

2. Listar los workspace
`terraform workspace list`

3. Crear un workspace
`terraform workspace new dev`

4. Seleccionar o cambiar de Workspace
`terraform workspace select dev`

5. saber el workspace actual
`terraform workspace show`

6. Eliminar 
`terraform workspace delete dev`

7. Inicializar terraform
`terraform init`

> **Nota sobre el backend S3:** El estado de Terraform se almacena en el bucket S3 `ws-base-bucket`.
> Ese bucket debe existir en la cuenta AWS **antes** de ejecutar `terraform init`.
> Si acabas de cambiar el backend (de local a S3), ejecuta:
> ```bash
> terraform init -migrate-state
> ```
> para migrar el estado local existente al bucket S3.

8. Realizar el plan de despliegue
`terraform plan` si se desea salida `terraform plan -out=tfplan`
_de acuerdo a los comparado el crea o elimina según aplique_

9. Aplicar o desplegar
`terraform apply` o `terraform apply "tfplan"`

10. Reconfigurar cuando hay cambios
`terraform reconfigure`

11. Eliminar lo desplegado
`terraform destroy`

## Variables TF_VAR de prueba

Se incluye un script auxiliar para cargar variables TF_VAR con valores de testing:

- [scripts/set-tfvars-test.sh](scripts/set-tfvars-test.sh)

Este script es solo para pruebas locales y laboratorios.
No debe usarse en producción porque incluye credenciales dummy.

Uso recomendado en la misma shell:

```bash
source scripts/set-tfvars-test.sh
```

Verificación rápida:

```bash
echo "$TF_VAR_rds_engine"
echo "$TF_VAR_rds_password"
```

Para limpiar variables de prueba en la sesión actual:

```bash
unset TF_VAR_rds_engine TF_VAR_rds_engine_version TF_VAR_rds_instance_class
unset TF_VAR_rds_allocated_storage TF_VAR_rds_db_name TF_VAR_rds_username
unset TF_VAR_rds_password TF_VAR_rds_skip_final_snapshot
```



## Link a redes
[ver aquí](https://visualsubnetcalc.com/index.html?c=1N4IgbiBcIEwgNCARlEBGAnDAdGgbABy7YAMA9DACwIgDOUoJA9gyCQA6skCOrAdqhoBjQQF9EaXpFADowsePSdpsKaEoAnfoMQi5igKxaVskPP2KAzGpB5jMnSD1nFAdnshT5l6N++gA)


## Conectarse al cluster K3S después del `terraform apply`

Durante la creación del clúster, el nodo master instala automáticamente Helm y despliega `aws-efs-csi-driver` desde el repositorio `https://kubernetes-sigs.github.io/aws-efs-csi-driver/` en el namespace `kube-system`.

Los nodos K3S se encuentran en la **subnet privada** y no tienen IP pública.  
El acceso de administración se realiza **exclusivamente** a través de **AWS SSM Session Manager** — no se necesita SSH ni abrir ningún puerto al exterior.

> Lens no importa un "manifiesto" de Kubernetes para administrar el clúster; lo que necesita es un archivo `kubeconfig`.
> En este proyecto ese archivo se puede extraer desde el Master y usarlo con un túnel local hacia el API Server de K3S.

### Prerrequisitos

```bash
# AWS CLI v2
aws --version

# Plugin de Session Manager para AWS CLI
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
session-manager-plugin --version

# kubectl
kubectl version --client
```

### 1. Obtener los IDs de las instancias

Después de `terraform apply`, los IDs de las instancias aparecen en los outputs:

```bash
terraform output k3s_master_instance_id   # e.g. i-0abc123def456789a
terraform output k3s_worker_instance_id   # e.g. i-0abc123def456789b
terraform output k3s_master_public_ip     # e.g. 54.123.45.67
terraform output k3s_worker_public_ip     # e.g. 54.123.45.68
```

Nota: si las instancias siguen en subnet privada, los outputs de IP pública pueden aparecer vacíos hasta que se les asigne una IP pública o Elastic IP.

También puedes ver todos los comandos listos para copiar:

```bash
terraform output k3s_ssm_connect_master
terraform output k3s_ssm_connect_worker
terraform output k3s_kubectl_port_forward
terraform output rds_endpoint
terraform output rds_db_name
terraform output rds_username
```

Para ver la cadena de conexión sensible:

```bash
terraform output rds_connection_string
```

### 2. Abrir una sesión de terminal en el Master

**Bash**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1
```

**PowerShell**

```powershell
$MasterId = terraform output -raw k3s_master_instance_id
aws ssm start-session `
  --target $MasterId `
  --region us-east-1
```

**CMD**

```bat
for /f "delims=" %i in ('terraform output -raw k3s_master_instance_id') do aws ssm start-session --target %i --region us-east-1
```

Una vez dentro puedes ejecutar, por ejemplo:

```bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

### 3. Acceder a n8n y Ollama API desde tu equipo local (AWS SSM)

Como el master K3S esta en subnet privada, desde tu equipo local debes usar un tunel SSM al puerto 80 del master.

Puedes consultar los outputs de URL (referenciales dentro de la VPC):

```bash
terraform output deploy_n8n_url
terraform output deploy_ollama_url
```

Abre el tunel SSM (deja esta terminal abierta):

**Bash**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'
```

**PowerShell**

```powershell
$MasterId = terraform output -raw k3s_master_instance_id
aws ssm start-session `
  --target $MasterId `
  --region us-east-1 `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'
```

**CMD**

```bat
for /f "delims=" %i in ('terraform output -raw k3s_master_instance_id') do aws ssm start-session --target %i --region us-east-1 --document-name AWS-StartPortForwardingSession --parameters "{\"portNumber\":[\"80\"],\"localPortNumber\":[\"8080\"]}"
```

Con el tunel activo, accede desde tu navegador o cliente local:

```text
http://127.0.0.1:8080/n8n
http://127.0.0.1:8080/ollama
```

Prueba rapida de la API de Ollama:

```bash
curl http://127.0.0.1:8080/ollama/api/tags
```

Si necesitas HTTPS (443), debes configurar certificado/TLS en Traefik y abrir un tunel SSM al puerto 443.

### 4. Generar el `kubeconfig` para Lens o `kubectl`

Este archivo sirve para ambos usos: conectarte desde consola con `kubectl` o importarlo en Lens para administración gráfica.

Si prefieres un flujo automático, puedes usar el script `scripts/generate-k3s-kubeconfig.sh`:

```bash
bash scripts/generate-k3s-kubeconfig.sh
```

También admite salida y región personalizadas:

```bash
bash scripts/generate-k3s-kubeconfig.sh -o /tmp/k3s.yaml -r us-east-1
```

El flujo correcto es:

1. abrir un port-forward del API Server del Master hacia `127.0.0.1:6443`
2. extraer el archivo `/etc/rancher/k3s/k3s.yaml` del Master con SSM
3. cambiar el servidor del `kubeconfig` a `https://127.0.0.1:6443`
4. importar ese archivo en Lens o usarlo con `kubectl`

**Paso 4a — dejar abierto el túnel al puerto 6443:**

**Bash**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'
```

**PowerShell**

```powershell
$MasterId = terraform output -raw k3s_master_instance_id
aws ssm start-session `
  --target $MasterId `
  --region us-east-1 `
  --document-name AWS-StartPortForwardingSession `
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'
```

**CMD**

```bat
for /f "delims=" %i in ('terraform output -raw k3s_master_instance_id') do aws ssm start-session --target %i --region us-east-1 --document-name AWS-StartPortForwardingSession --parameters "{\"portNumber\":[\"6443\"],\"localPortNumber\":[\"6443\"]}"
```

**Paso 4b — exportar el kubeconfig desde el Master:**

**Bash**

```bash
CMD_ID=$(aws ssm send-command \
  --instance-ids "$(terraform output -raw k3s_master_instance_id)" \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters commands='["sudo cat /etc/rancher/k3s/k3s.yaml"]' \
  --query 'Command.CommandId' \
  --output text)

aws ssm wait command-executed \
  --command-id "$CMD_ID" \
  --instance-id "$(terraform output -raw k3s_master_instance_id)" \
  --region us-east-1

aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id "$(terraform output -raw k3s_master_instance_id)" \
  --region us-east-1 \
  --query 'StandardOutputContent' \
  --output text > k3s.yaml

sed -i 's|https://.*:6443|https://127.0.0.1:6443|g' k3s.yaml
```

**PowerShell**

```powershell
$MasterId = terraform output -raw k3s_master_instance_id
$CmdId = aws ssm send-command `
  --instance-ids $MasterId `
  --region us-east-1 `
  --document-name AWS-RunShellScript `
  --parameters 'commands=["sudo cat /etc/rancher/k3s/k3s.yaml"]' `
  --query 'Command.CommandId' `
  --output text

aws ssm wait command-executed `
  --command-id $CmdId `
  --instance-id $MasterId `
  --region us-east-1

aws ssm get-command-invocation `
  --command-id $CmdId `
  --instance-id $MasterId `
  --region us-east-1 `
  --query 'StandardOutputContent' `
  --output text | Out-File -Encoding ascii k3s.yaml

(Get-Content k3s.yaml) -replace 'https://.*:6443', 'https://127.0.0.1:6443' | Set-Content -Encoding ascii k3s.yaml
```

**CMD**

```bat
setlocal EnableDelayedExpansion
for /f "delims=" %i in ('terraform output -raw k3s_master_instance_id') do set MASTER_ID=%i
for /f "delims=" %c in ('aws ssm send-command --instance-ids "!MASTER_ID!" --region us-east-1 --document-name AWS-RunShellScript --parameters commands="[\"sudo cat /etc/rancher/k3s/k3s.yaml\"]" --query "Command.CommandId" --output text') do set CMD_ID=%c
aws ssm wait command-executed --command-id "!CMD_ID!" --instance-id "!MASTER_ID!" --region us-east-1
aws ssm get-command-invocation --command-id "!CMD_ID!" --instance-id "!MASTER_ID!" --region us-east-1 --query "StandardOutputContent" --output text > k3s.yaml
powershell -NoProfile -Command "(Get-Content k3s.yaml) -replace 'https://.*:6443','https://127.0.0.1:6443' | Set-Content -Encoding ascii k3s.yaml"
```

**Paso 4c — usar el kubeconfig desde consola:**

```bash
export KUBECONFIG=$PWD/k3s.yaml
kubectl get nodes
kubectl get pods -A
```

**Paso 4d — usar el kubeconfig en Lens:**

Importa el archivo `k3s.yaml` en Lens y mantén abierta la terminal del port-forward mientras uses la interfaz.

### 5. Abrir una sesión en el Worker

**Bash**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_worker_instance_id) \
  --region us-east-1
```

**PowerShell**

```powershell
$WorkerId = terraform output -raw k3s_worker_instance_id
aws ssm start-session `
  --target $WorkerId `
  --region us-east-1
```

**CMD**

```bat
for /f "delims=" %i in ('terraform output -raw k3s_worker_instance_id') do aws ssm start-session --target %i --region us-east-1
```

---

## Alternativas si Lens no conecta

1. Usar `kubectl` en local con el mismo `k3s.yaml` y el túnel SSM abierto. Es la opción más simple y no requiere cambiar la infraestructura.
2. Abrir acceso directo al API Server con una IP pública o un Load Balancer. Funciona bien para pruebas, pero no es lo ideal porque expone el plano de control.
3. Crear un bastión con SSH y copiar el `kubeconfig` desde ahí. Es útil si prefieres trabajar por SSH, pero añade una máquina más que administrar.
4. Mantener SSM y automatizar la exportación del `kubeconfig` con un script o un output adicional de Terraform. Es la mejor opción si quieres repetir el flujo sin pasos manuales.