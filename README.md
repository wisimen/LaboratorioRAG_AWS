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

8. Realizar el plan de despliegue
`terraform plan`
_de acuerdo a los comparado el crea o elimina según aplique_

9. Aplicar o desplegar
`terraform apply`

10. Reconfigurar cuando hay cambios
`terraform reconfigure`

