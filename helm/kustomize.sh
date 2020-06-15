#!/bin/sh

cd "$(dirname "$0")"

cat > base.yaml
exec kubectl kustomize

rm base.yaml
