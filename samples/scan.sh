#!/bin/bash

# This sample script adds a GitHub workflow that will
# scan container images.

WORKFLOW_PATH=.github/workflows/container-scan-trivy.yml

HAS_SCAN=$(grep -R trivy-action .github/workflows/)
if [ ! -z "$HAS_SCAN" ]; then
  echo "trivy-action found in .github/workflows/."
  exit 0
fi

HAS_DOCKERFILES=$(find . -name "Dockerfile")
if [ -z "$HAS_DOCKERFILES" ]; then
  echo "No Dockerfiles found."
  exit 0
fi

echo "No trivy-action found in .github/workflows/."
mkdir -p .github/workflows/
touch $WORKFLOW_PATH

git checkout -b trivy-scan

cat <<EOF > $WORKFLOW_PATH
---
name: trivy-container-scan

# Run for all pushes to main and pull requests when Go or YAML files change
on:
  push:
    branches:
      - main
  schedule:
    - cron: '15 15 * * 2'
  pull_request:

jobs:

EOF

i=1
for path in $(find . -name Dockerfile); do
cat <<EOF >> $WORKFLOW_PATH
  scan-trivy-$i:
    name: sec-scan-trivy-$i
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

EOF

  if [ -z "$(grep -i 'go.*build ' $path)" ]; then
    echo "Dockerfile doesn't build the container."

    if [ ! -z "$(find . -name *.go)" ]; then
      echo "* is a Go project."

      if [ -f Makefile ]; then
        build_target=$(grep -E "^build.*:" Makefile | awk '{print $1}' | sed 's/://')
        if [ ! -z "$build_target" ]; then
          echo "Makefile has build target: $build_target"
cat <<EOF >> $WORKFLOW_PATH
      - name: Build
        run: |
          make $build_target

EOF
        fi
      fi

      if [ ! -z "$(grep 'Copy the binary' $path)" ]; then
        echo "goreleaser is used."
        copystmt=$(grep -A1 'Copy the binary' $path | tail -1)
        if [ ! -z "$(echo $copystmt | grep 'COPY')" ]; then
          echo "COPY statement found."
          copyfrom=$(echo $copystmt | awk '{print $2}')
cat <<EOF >> $WORKFLOW_PATH
      - name: Build go binary
        run: |
          go build -o $copyfrom .

EOF
        fi
      fi
    fi
  fi

cat <<EOF >> $WORKFLOW_PATH
      - name: Build container image
        uses: docker/build-push-action@v3
        with:
          context: .
          file: $path
          push: false
          load: true
          tags: localbuild/sec-scan-trivy:latest

      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: localbuild/sec-scan-trivy:latest
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL'

EOF
  i=$((i+1))
  git add $WORKFLOW_PATH
done

templatefile=$(mktemp)

cat <<EOF > $templatefile
Add container security scanning

This adds a workflow that runs Trivy [1] on all Dockerfiles in the repository.

The intention is to verify that Pull Requests don't introduce security vulnerabilities.

The workflow will also run on a specified cadence (Tuesdays at 15:15 UTC). Which
will allow us to discover new package-level vulnerabilities in the container(s).

Note that scanning container images in clusters will be handled elsewhere and not
as part of this PR.

[1] https://aquasecurity.github.io/trivy/
EOF

git commit -F $templatefile

git push origin trivy-scan

gh label create security -f --description "Security-Related" --color "#0000FF"

sleep 2

gh pr create -a @me -l security --head trivy-scan -f -R $(gh repo view --json name,owner -q '.owner.login + "/" + .name')
