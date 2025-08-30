# terraform
Terraform assets

## Usage

The infrastructure is split into two Terraform configurations. Apply the Docker bootstrap first, then configure Jenkins:

```bash
terraform -chdir=docker init
terraform -chdir=docker apply

terraform -chdir=jenkins init
terraform -chdir=jenkins apply
```

The `pipeline.sh` and Jenkins pipeline use this two-stage approach automatically.
