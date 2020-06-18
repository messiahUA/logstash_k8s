#!/bin/sh -eu

DIFF="$(git diff --name-status --diff-filter=M HEAD~1..HEAD pipeline Dockerfile)"

[ -z "${DIFF}" ] && exit 0

TAG="$(git rev-parse --short HEAD)"

docker login -u "${DOCKER_LOGIN}" -p "${DOCKER_PASS}"

docker build -t "${DOCKER_IMAGE_NAME}:${TAG}" .
docker push "${DOCKER_IMAGE_NAME}:${TAG}"
