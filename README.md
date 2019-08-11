# Security in DevOps

## Introduction

adjasljdsl

## Prerequisites

** ACR and docker. Good start here: https://github.com/texnokot/WebGoatonAzureACI

## Add 3rd party library scanner WhiteSource Bolt

Enable extension from marketplace. Then install it either thru visual designer or just add task directly in yml.

Add WhiteSource task after Maven test. You can do thru Task designer on a right side by looking after WhiteSource task and adding root directory of your code. Or directly in yml:
    - task: WhiteSource Bolt@19
      inputs:
        cwd: 'SecurityinDevOps'

After WhiteSource install, check the report under finished build task. You will see new tab WhiteSource Bolt Build Report. You will see something like this 
## Let's scan containers

### Install Anchor server on AKS

Grab instructions from: https://anchore.com/azure-anchore-kubernetes-service-cluster-with-helm/

Add your ACR registry for Anchore analyzing.
anchore-cli registry add --registry-type <Type> <Registry> <Username> <Password>
anchore-cli --u admin --p foobar --url http://23.97.144.166:8228/v1 registry add --registry-type docker_v2 acrwebgoat.azurecr.io acrWebGoat "m/KoaHtgbyLx9lpa88tDbOdGq9bizvyU"

When Anchore service is up and running update Azure KeyVault with username and password from Anchore.
Add server address in yml under variables:
  - name: 'anchorServer'
    value: 'http://ANCHORE_ADDRESS:8228/v1'

Add the stage for security scanning. One of the option is to run it in the parallel to deployment to Dev stage. So you can add steps with stage description before DeployToDev stage
`
# Testing security in the ACR
- stage: SecurityContainer
  displayName: Container security scans stage
  jobs:  
  - job: SecurityContainer
    displayName: Container security job
    pool:
      vmImage: 'ubuntu-latest'

    steps:
    - task: Bash@3
      displayName: Install anchorecli
      inputs:
        targetType: 'inline'
        script: 'sudo pip install anchorecli'

    - bash: anchore-cli --json --url $(anchorServer) --u $(anchorUser) --p $(anchorPassword) image vuln $(acrRegistry)/$(imageRepository):$(tag) os > image-vuln.json
      displayName: Scan for the vulnerabilities and save the report image-vuln.json
      continueOnError: true

    - bash: anchore-cli --json --url $(anchorServer) --u $(anchorUser) --p $(anchorPassword) evaluate check $(acrRegistry)/$(imageRepository):$(tag) --detail > image-policy.json
      displayName: Scan for the policy violations and save the report image-policy.json
      continueOnError: true

    - task: CopyFiles@2
      displayName: 'Copy Reports for publishing'
      inputs:
        Contents: '*.json'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'

    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifact: anchore-reports'
      inputs:
        ArtifactName: 'anchore-reports'
`
Run it. Check reports in the artifacts of build. You should see reports of Anchore. 