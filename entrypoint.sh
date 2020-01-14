#!/bin/bash

REGISTRY_URL="https://registry.hub.docker.com/v1/repositories/__IMAGE_NAME__/tags"

DEFAULT_FILE_PATH="templates/deployment.yaml"
SEARCH_PATH=${INPUT_FILEPATH:-$DEFAULT_FILE_PATH}
# Remove optional leading slash
SEARCH_PATH=${SEARCH_PATH#/}

shopt -s nullglob
COMPONENTS=(*/)
shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

for COMPONENT in ${COMPONENTS[@]}; do

  # Remove optional trailing slash
  COMPONENT=${COMPONENT/\//""}

  SR_FILE="${COMPONENT}/${SEARCH_PATH}" #S(earchAnd)R(eplace)_FILE

  echo "Updating GitOps YAMLs for '${COMPONENT}'"
  echo "Search path: '${SR_FILE}'"

  if [[ ! -f "${SR_FILE}" ]]; then
    echo "Skipping... File '${SR_FILE}' does not exist for '${COMPONENT}'."
    echo ""
    continue
  fi

  #Initial implementation
  # - updated to support both 'image' and 'applicationImage'
  # - 'image' is standard in k8s Deployment YAMLs
  # - 'applicationImage' is used in Appsody app-deploy.yaml
  #IMAGE_NAME=$(cat ${COMPONENT}/${SEARCH_PATH} | grep "image:" | sed 's/.*image\: \"//' | sed 's/\:.*$//')
  IMAGE_NAME=$(cat ${COMPONENT}/${SEARCH_PATH} | grep "mage:" | sed -e 's/^.*mage\: //' -e 's/\:.*$//' -e 's/"//g')
  echo "Calculated image name: ${IMAGE_NAME}"

  # Extract {REPO_NAME} from {REPO_NAME}/{IMAGE_NAME}
  REPO_NAME=$(echo $IMAGE_NAME | sed 's/\(.*\)\/.*/\1/')
  echo "Calculated image repository: ${REPO_NAME}"

  # Split {REPO_NAME}/{IMAGE_NAME} into only {IMAGE_NAME}
  IMAGE_SHORT_NAME=${IMAGE_NAME/${REPO_NAME}\//""}
  echo "Calculated image short name: ${IMAGE_SHORT_NAME}"

  #Initial implementation
  # - updated to support both 'image' and 'applicationImage'
  # - 'image' is standard in k8s Deployment YAMLs
  # - 'applicationImage' is used in Appsody app-deploy.yaml
  #CURRENT_VER_TAG=$(cat ${COMPONENT}/${SEARCH_PATH} | grep "image:" | grep --only-matching -e "[Vv]\?[0-9]*\.[0-9]*\.[0-9]*")
  CURRENT_VER_TAG=$(cat ${COMPONENT}/${SEARCH_PATH} | grep "mage:" | grep --only-matching -e "[Vv]\?[0-9]*\.[0-9]*\.[0-9]*")
  echo "Calculated current tag: ${CURRENT_VER_TAG}"

  LATEST_VER_URL=${REGISTRY_URL/__IMAGE_NAME__/${IMAGE_NAME}}
  #Get latest tag, formatted for greatest semantic version value with explicit format of X.Y.Z only
  LATEST_VER_TAG=$(curl --silent ${LATEST_VER_URL} | jq -r '.[] | select(.name|test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) | .name' | sort -V | tail -n1)
  echo "Calculated latest tag: ${LATEST_VER_TAG}"

  ## TODO REFACTOR TO USE yq SINCE WE ARE RUNNING IN CONTAINER
  IMAGE_TAG_PATTERN="s/${IMAGE_SHORT_NAME}\:${CURRENT_VER_TAG}/${IMAGE_SHORT_NAME}\:${LATEST_VER_TAG}/"
  # Replace current version (in the pattern of kcontainer-ui:X.Y.Z)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -e ${IMAGE_TAG_PATTERN} ${COMPONENT}/${SEARCH_PATH}
  else
    sed --in-place --expression ${IMAGE_TAG_PATTERN} ${COMPONENT}/${SEARCH_PATH}
  fi

  echo ""
done
