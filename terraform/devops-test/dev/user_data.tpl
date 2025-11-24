#!/bin/bash
set -eux

# Dev user-data: build, tag, push to dev ECR repo and deploy docker-compose
# Variables provided by terraform templatefile:
# - project_name, environment, region, git_repo, image_name, image_tag
# - ecr_registry  (expected to be the full repository URL, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/myrepo)

export REGION="${region}"
export ENV="dev"
export GIT_REPO="${git_repo}"
export IMAGE_NAME="${image_name}"
export IMAGE_TAG="${image_tag}"
export ECR_REGISTRY="${ecr_registry}"

# Install prerequisites (Amazon Linux 2/2023 compatible commands)
if command -v yum >/dev/null 2>&1; then
  yum update -y || true
  yum install -y git docker python3-pip
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y || true
  apt-get install -y git docker.io python3-pip
fi

pip3 install --no-cache-dir docker-compose awscli

systemctl enable --now docker || true

# Helper: login to ECR
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

# Build, tag and push to dev ECR and deploy compose
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

REGISTRY_TO_USE="$ECR_REGISTRY"
if [ -z "$REGISTRY_TO_USE" ] || [ "$REGISTRY_TO_USE" == "null" ]; then
  echo "No registry provided by template; expecting ecr_registry in tfvars for dev"
  exit 0
fi

if ecr_login "$REGISTRY_TO_USE"; then
  docker tag "$IMAGE_NAME:$IMAGE_TAG" "$REGISTRY_TO_USE:$IMAGE_TAG"
  docker push "$REGISTRY_TO_USE:$IMAGE_TAG"
fi

# Replace image in docker-compose.yml if present (use repository URL + tag)
if [ -f docker-compose.yml ]; then
  sed -i "s|image: .*|image: ${REGISTRY_TO_USE}:${IMAGE_TAG}|g" docker-compose.yml || true
  docker-compose up -d --remove-orphans
fi

exit 0
