# LaboratorioRAG_AWS

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



## Link a redes
[ver aquí](https://visualsubnetcalc.com/index.html?c=1N4IgbiBcIEwgNCARlEBGAnDAdGgbABy7YAMA9DACwIgDOUoJA9gyCQA6skCOrAdqhoBjQQF9EaXpFADowsePSdpsKaEoAnfoMQi5igKxaVskPP2KAzGpB5jMnSD1nFAdnshT5l6N++gA)


## Conectarse al cluster K3S después del `terraform apply`

Los nodos K3S se encuentran en la **subnet privada** y no tienen IP pública.  
El acceso de administración se realiza **exclusivamente** a través de **AWS SSM Session Manager** — no se necesita SSH ni abrir ningún puerto al exterior.

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
```

También puedes ver todos los comandos listos para copiar:

```bash
terraform output k3s_ssm_connect_master
terraform output k3s_ssm_connect_worker
terraform output k3s_kubectl_port_forward
```

### 2. Abrir una sesión de terminal en el Master

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1
```

Una vez dentro puedes ejecutar, por ejemplo:

```bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

### 3. Acceder al API Server de K3S con `kubectl` desde tu máquina local

El plugin de Session Manager permite hacer **port-forward** del puerto 6443 del Master
hacia tu máquina local sin abrir ningún puerto en el Security Group:

**Paso 3a — Iniciar el port-forward en una terminal:**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'
```

**Paso 3b — Copiar el kubeconfig desde el Master (en otra terminal):**

```bash
# Obtener el kubeconfig del Master y guardarlo localmente
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1 \
  --document-name AWS-RunShellScript \
  --parameters '{"commands":["cat /etc/rancher/k3s/k3s.yaml"]}' \
  --query 'StandardOutputContent' \
  --output text > /tmp/k3s.yaml

# Ajustar el servidor para apuntar al port-forward local
# Linux:
sed -i 's|https://.*:6443|https://127.0.0.1:6443|g' /tmp/k3s.yaml
# macOS (BSD sed requiere argumento de extensión):
# sed -i '' 's|https://.*:6443|https://127.0.0.1:6443|g' /tmp/k3s.yaml
```

**Paso 3c — Usar kubectl apuntando al kubeconfig local:**

```bash
export KUBECONFIG=/tmp/k3s.yaml
kubectl get nodes
kubectl get pods -A
```

### 4. Abrir una sesión en el Worker

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_worker_instance_id) \
  --region us-east-1
```

---

## comando para conectarse por ssh a una instancia de ec2
ssh -i C://...key.pem

### pendiente crear:
- respuesta de peticion
- dividir en modulos