#!/bin/bash

REGISTRY_URL="https://registry.hub.docker.com/v1/repositories/__IMAGE_NAME__/tags"

##TODO## Explode into CSL for 'input'
COMPONENTS=(
  fleetms
  kc-ui
  ordercommandms
  orderqueryms
  reefersimulator
  springcontainerms
  voyagesms
)

for COMPONENT in ${COMPONENTS[@]}; do
  echo "Updating GitOps YAMLs for '${COMPONENT}'"
  IMAGE_NAME=$(cat ${COMPONENT}/templates/deployment.yaml | grep "image:" | sed 's/.*image\: \"//' | sed 's/\:.*$//')
  echo "Calculated image name: ${IMAGE_NAME}"

  CURRENT_VER_TAG=$(cat ${COMPONENT}/templates/deployment.yaml | grep "image:" | grep --only-matching -e "[0-9]*\.[0-9]*\.[0-9]*")
  echo "Calculated current tag: ${CURRENT_VER_TAG}"

  LATEST_VER_URL=${REGISTRY_URL/__IMAGE_NAME__/${IMAGE_NAME}}
  #Get latest tag, formatted for greatest semantic version value
  LATEST_VER_TAG=$(curl --silent ${LATEST_VER_URL} | jq -r '.[] | select(.name|test("[0-9].[0-9].[0-9]")) | .name' | sort -V | tail -n1)
  echo "Calculated latest tag: ${LATEST_VER_TAG}"

  #####
  ## TODO REFACTOR TO USE yq SINCE WE ARE RUNNING IN CONTAINER
  #####
  REPO_NAME=ibmcase
  #ALTERNATIVE: REPO_NAME=$(echo $IMAGE_NAME | sed 's/\(.*\)\/.*/\1/')
  # Split {REPO_NAME}/{IMAGE_NAME} into only {IMAGE_NAME}
  IMAGE_SHORT_NAME=${IMAGE_NAME/${REPO_NAME}\//""}
  #ALTERNATIVE: IMAGE_SHORT_NAME=$(echo $IMAGE_NAME | sed 's/.*\/\(.*\)\:.*/\1/')

  # Replace current version (in the pattern of kcontainer-ui:X.Y.Z)
  sed -i "" -e "s/${IMAGE_SHORT_NAME}\:${CURRENT_VER_TAG}/${IMAGE_SHORT_NAME}\:${LATEST_VER_TAG}/" ${COMPONENT}/templates/deployment.yaml
  #####
  ## END TODO REFACTOR
  #####

  cat ${COMPONENT}/templates/deployment.yaml

  echo ""
done
