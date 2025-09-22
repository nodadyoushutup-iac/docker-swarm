# terraform
Terraform assets

## Usage

The infrastructure is split into two Terraform configurations. Apply the Docker bootstrap first, then configure Jenkins:

```bash
terraform -chdir=docker init -backend-config="/path/to/backend.hcl"
terraform -chdir=docker apply

terraform -chdir=jenkins init
terraform -chdir=jenkins apply
```

### Backend configuration

Terraform stores state for this project in an S3-compatible bucket. By default the
configuration uses the bucket `terraform` and the key `docker-swarm/terraform.tfstate`.
Provide a backend configuration file when running `terraform init` if you need to
override these defaults or connect to an alternative endpoint such as MinIO:

```hcl
bucket                      = "terraform"
key                         = "docker-swarm/terraform.tfstate"
endpoint                    = "http://minio.example.com:9000"
access_key                  = "<access-key>"
secret_key                  = "<secret-key>"
skip_credentials_validation = true
skip_region_validation      = true
```

The `pipeline/pipeline.sh` script and Jenkins pipeline use this two-stage approach automatically.

Use the helper script to run both stages at once, optionally passing tfvars files:

```bash
./pipeline/pipeline.sh --docker-tfvars docker.tfvars --jenkins-tfvars jenkins.tfvars
```
