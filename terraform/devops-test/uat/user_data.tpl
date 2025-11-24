#!/bin/bash
set -eux

# UAT user-data: build, push to UAT ECR (and optionally push to PROD ECR), then deploy docker-compose
# Variables provided by terraform templatefile:
# - project_name, environment, region, git_repo, image_name, image_tag
# - ecr_registry  (UAT repository URL)
# - ecr_registry_prod (optional PROD repository URL to also push a copy)

export REGION="${region}"
export ENV="uat"
export GIT_REPO="${git_repo}"
export IMAGE_NAME="${image_name}"
export IMAGE_TAG="${image_tag}"
export ECR_REGISTRY_UAT="${ecr_registry}"
export ECR_REGISTRY_PROD="${ecr_registry_prod}"

# Install prerequisites
if command -v yum >/dev/null 2>&1; then
  yum update -y || true
  yum install -y git docker python3-pip
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y || true
  apt-get install -y git docker.io python3-pip
fi

pip3 install --no-cache-dir docker-compose awscli

systemctl enable --now docker || true

ecr_login() {
  local registry="$1"
  if [ -z "$registry" ] || [ "$registry" == "null" ]; then
    echo "no registry provided"
    return 1
  fi
  aws --region "$REGION" ecr get-login-password | docker login --username AWS --password-stdin "$registry"
}

WORKDIR=/opt/app
rm -rf "$WORKDIR"
git clone "$GIT_REPO" "$WORKDIR"
cd "$WORKDIR"

# Build locally
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

if [ -z "$ECR_REGISTRY_UAT" ] || [ "$ECR_REGISTRY_UAT" == "null" ]; then
  echo "No UAT registry provided by template; expecting ecr_registry in tfvars for uat"
  exit 0
fi

# Push to UAT
if ecr_login "$ECR_REGISTRY_UAT"; then
  docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ECR_REGISTRY_UAT:$IMAGE_TAG"
  docker push "$ECR_REGISTRY_UAT:$IMAGE_TAG"
fi

# Optionally also push to PROD registry if provided
if [ -n "$ECR_REGISTRY_PROD" ] && [ "$ECR_REGISTRY_PROD" != "null" ]; then
  if ecr_login "$ECR_REGISTRY_PROD"; then
    docker tag "$IMAGE_NAME:$IMAGE_TAG" "$ECR_REGISTRY_PROD:$IMAGE_TAG"
    docker push "$ECR_REGISTRY_PROD:$IMAGE_TAG"
  fi
fi

# Replace image in docker-compose.yml to use the UAT repo + tag
if [ -f docker-compose.yml ]; then
  sed -i "s|image: .*|image: ${ECR_REGISTRY_UAT}:${IMAGE_TAG}|g" docker-compose.yml || true
  docker-compose up -d --remove-orphans
fi

exit 0
