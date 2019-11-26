# Update GitOps

A GitHub action to update a collection of Kubernetes YAMLs for use in a GitOps-based deployment strategy.

## Usage

```yml
      - name: Update GitOps YAMLs
        id: update-gitops-yamls
        uses: ibm-cloud-architecture/actions-update-gitops@master
```

The action currently expects to be run inside a working directory (by default, this is the `/github/workspace` directory in the virtual environment), with a collection of application component deployment YAML files that have been created by `helm template` commands with the following folder structure:

```
      /{component-a}/templates/deployment.yaml
      /{component-a}/templates/service.yaml
      /{component-b}/templates/deployment.yaml
      /{component-b}/templates/service.yaml
      ...
      /{component-n}/templates/deployment.yaml
      /{component-n}/templates/service.yaml
```

The action gets the latest Docker image versions from Docker Hub by searching against the image repositories used in each `deployment.yaml` and updates it inline in each file to the latest version (as defined by semantic versioning rules).

It is outside the scope of this action to commit and push the modified files back to the owning repository.

## Parameters

To be deteremined

## Example
```yml
name: Update GitOps deployments
on: [push]
env:
  DESIRED_BRANCH: gitops-yaml-branch
jobs:
  update-gitops-deployments:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Checkout default sandbox branch
      id: checkout-sandbox-branch
      run: |
        git checkout ${DESIRED_BRANCH}
    - name: Update GitOps YAMLs
      id: update-gitops-yamls
      uses: ibm-cloud-architecture/actions-update-gitops@master
    - name: Commit & push modified files
      id: commit-and-push-files
      env:
        GITHUB_TOKEN: ...
        GITHUB_ACTOR: ...
      run: |
        ...
```

## License
[Apache2](https://github.com/ibm-cloud-architecture/actions-update-gitops/blob/master/LICENSE)
