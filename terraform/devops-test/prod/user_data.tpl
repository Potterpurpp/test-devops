#!/bin/bash
set -eux

# Prod user-data: pull image from PROD ECR and deploy docker-compose (no build)
# Variables provided by terraform templatefile:
# - project_name, environment, region, git_repo, image_name, image_tag
# - ecr_registry (the PROD repository URL)

export REGION="${region}"
export ENV="prod"
export GIT_REPO="${git_repo}"
export IMAGE_NAME="${image_name}"
export IMAGE_TAG="${image_tag}"
export ECR_REGISTRY="${ecr_registry}"

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

REGISTRY_TO_USE="$ECR_REGISTRY"
if [ -n "$REGISTRY_TO_USE" ] && [ "$REGISTRY_TO_USE" != "null" ]; then
  if ecr_login "$REGISTRY_TO_USE"; then
    docker pull "$REGISTRY_TO_USE:$IMAGE_TAG" || true
  fi
else
  echo "No PROD registry provided by template; expecting ecr_registry in tfvars for prod"
fi

if [ -f docker-compose.yml ]; then
  if [ -n "$REGISTRY_TO_USE" ] && [ "$REGISTRY_TO_USE" != "null" ]; then
    sed -i "s|image: .*|image: ${REGISTRY_TO_USE}:${IMAGE_TAG}|g" docker-compose.yml || true
  fi
  docker-compose up -d --remove-orphans
fi

exit 0
