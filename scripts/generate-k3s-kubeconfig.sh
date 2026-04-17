#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Uso:
  scripts/generate-k3s-kubeconfig.sh [-o archivo] [-r region]

Opciones:
  -o  Ruta del kubeconfig de salida. Por defecto: ./k3s.yaml
  -r  Región de AWS. Por defecto: us-east-1

El script obtiene el kubeconfig desde el Master de K3S mediante AWS SSM,
reemplaza el servidor por https://127.0.0.1:6443 y deja el archivo listo
para kubectl o Lens.
EOF
}

output_file="k3s.yaml"
region="${AWS_REGION:-us-east-1}"

while getopts ":o:r:h" opt; do
  case "${opt}" in
    o) output_file="${OPTARG}" ;;
    r) region="${OPTARG}" ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v terraform >/dev/null 2>&1; then
  echo "Error: terraform no está instalado o no está en PATH." >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws no está instalado o no está en PATH." >&2
  exit 1
fi

if ! command -v sed >/dev/null 2>&1; then
  echo "Error: sed no está instalado o no está en PATH." >&2
  exit 1
fi

master_instance_id="$(terraform output -raw k3s_master_instance_id)"

if [[ -z "${master_instance_id}" ]]; then
  echo "Error: no se pudo obtener k3s_master_instance_id desde Terraform." >&2
  exit 1
fi

command_id="$(aws ssm send-command \
  --instance-ids "${master_instance_id}" \
  --region "${region}" \
  --document-name AWS-RunShellScript \
  --parameters commands='["sudo cat /etc/rancher/k3s/k3s.yaml"]' \
  --query 'Command.CommandId' \
  --output text)"

aws ssm wait command-executed \
  --command-id "${command_id}" \
  --instance-id "${master_instance_id}" \
  --region "${region}"

aws ssm get-command-invocation \
  --command-id "${command_id}" \
  --instance-id "${master_instance_id}" \
  --region "${region}" \
  --query 'StandardOutputContent' \
  --output text > "${output_file}"

sed -i 's|https://.*:6443|https://127.0.0.1:6443|g' "${output_file}"

cat <<EOF
Kubeconfig generado en: ${output_file}

Antes de usarlo, deja abierto este túnel en otra terminal:
aws ssm start-session \\
  --target ${master_instance_id} \\
  --region ${region} \\
  --document-name AWS-StartPortForwardingSession \\
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'

Luego puedes usar:
export KUBECONFIG=$(pwd)/${output_file}
kubectl get nodes

O importar el archivo en Lens.
EOF