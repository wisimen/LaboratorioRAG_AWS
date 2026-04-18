#!/usr/bin/env bash
set -euo pipefail

# Script de apoyo para pruebas locales.
# NO usar estos valores en producción.

export TF_VAR_rds_engine='{"default":"postgres","dev":"postgres","test":"postgres","prod":"postgres"}'
export TF_VAR_rds_engine_version='{"default":"17.6","dev":"17.6","test":"17.6","prod":"17.6"}'
export TF_VAR_rds_instance_class='{"default":"db.t4g.micro","dev":"db.t4g.micro","test":"db.t4g.micro","prod":"db.t4g.small"}'
export TF_VAR_rds_allocated_storage='{"default":20,"dev":20,"test":20,"prod":100}'
export TF_VAR_rds_db_name='{"default":"n8ndb","dev":"n8ndb","test":"n8ndb","prod":"n8ndb"}'
export TF_VAR_rds_username='{"default":"n8nadmin","dev":"n8nadmin","test":"n8nadmin","prod":"n8nadmin"}'

# Passwords de PRUEBA (dummy). Reemplazar siempre en entornos reales.
export TF_VAR_rds_password='{"default":"TestOnlyDefaultPass123!","dev":"TestOnlyDevPass123!","test":"TestOnlyTestPass123!","prod":"TestOnlyProdPass123!"}'

export TF_VAR_rds_skip_final_snapshot='{"default":true,"dev":true,"test":true,"prod":false}'

echo "Variables TF_VAR de prueba cargadas en la sesion actual."
echo "Uso recomendado: source scripts/set-tfvars-test.sh"
echo "ADVERTENCIA: valores solo para testing, no para produccion."
