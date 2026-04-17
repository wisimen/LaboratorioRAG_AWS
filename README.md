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

### 3. Generar el `kubeconfig` para Lens o `kubectl`

Este archivo sirve para ambos usos: conectarte desde consola con `kubectl` o importarlo en Lens para administración gráfica.

El flujo correcto es:

1. abrir un port-forward del API Server del Master hacia `127.0.0.1:6443`
2. extraer el archivo `/etc/rancher/k3s/k3s.yaml` del Master con SSM
3. cambiar el servidor del `kubeconfig` a `https://127.0.0.1:6443`
4. importar ese archivo en Lens o usarlo con `kubectl`

**Paso 3a — dejar abierto el túnel al puerto 6443:**

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_master_instance_id) \
  --region us-east-1 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'
```

**Paso 3b — exportar el kubeconfig desde el Master:**

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

**Paso 3c — usar el kubeconfig desde consola:**

```bash
export KUBECONFIG=$PWD/k3s.yaml
kubectl get nodes
kubectl get pods -A
```

**Paso 3d — usar el kubeconfig en Lens:**

Importa el archivo `k3s.yaml` en Lens y mantén abierta la terminal del port-forward mientras uses la interfaz.

### 4. Abrir una sesión en el Worker

```bash
aws ssm start-session \
  --target $(terraform output -raw k3s_worker_instance_id) \
  --region us-east-1
```

---

## Alternativas si Lens no conecta

1. Usar `kubectl` en local con el mismo `k3s.yaml` y el túnel SSM abierto. Es la opción más simple y no requiere cambiar la infraestructura.
2. Abrir acceso directo al API Server con una IP pública o un Load Balancer. Funciona bien para pruebas, pero no es lo ideal porque expone el plano de control.
3. Crear un bastión con SSH y copiar el `kubeconfig` desde ahí. Es útil si prefieres trabajar por SSH, pero añade una máquina más que administrar.
4. Mantener SSM y automatizar la exportación del `kubeconfig` con un script o un output adicional de Terraform. Es la mejor opción si quieres repetir el flujo sin pasos manuales.