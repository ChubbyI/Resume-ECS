REGION       = "us-central1"
PROJECT_NAME = "ECS-resume"

VPC_CIDR  = "10.0.0.0/18"
PUB_SUB_1_CIDR = "10.0.1.0/24"
PUB_SUB_2_CIDR = "10.0.2.0/24"
PRI_SUB_1_CIDR = "10.0.10.0/24"
PRI_SUB_2_CIDR = "10.0.11.0/24"
HOSTED_ZONE = "chubiresume.com"

project_id      = "your-gcp-project-id"
container_image = "gcr.io/your-project-id/resume-app:latest"
domain_name     = "your-domain.com"  # Optional: Set if you have a custom domain
