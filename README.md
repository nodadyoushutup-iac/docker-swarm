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

The `pipeline/pipeline.sh` script and Jenkins pipeline use this two-stage approach automatically.

Use the helper script to run both stages at once, optionally passing tfvars files:

```bash
./pipeline/pipeline.sh --docker-tfvars docker.tfvars --jenkins-tfvars jenkins.tfvars
```
