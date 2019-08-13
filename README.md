# Implement Security in Azure DevOps CI/CD

<!-- TOC -->

- [Implement Security in Azure DevOps CI/CD](#implement-security-in-azure-devops-cicd)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Create Azure DevOps project and prepare WebGoat source code](#create-azure-devops-project-and-prepare-webgoat-source-code)
  - [Create Azure container registry and Azure Key Vault](#create-azure-container-registry-and-azure-key-vault)
  - [Configure CI/CD pipeline for Webgoat](#configure-cicd-pipeline-for-webgoat)
    - [Configure Build pipeline](#configure-build-pipeline)
    - [Configure the release pipeline](#configure-the-release-pipeline)

<!-- /TOC -->

## Introduction

Document shows how to implement security practices in Azure CI/CD pipeline to detect security issues and improve the state. Vulnerable application to test is WebGoat.
WebGoat is a deliberately insecure web application maintained by OWASP designed to teach web application security lessons. The project is available at [Github](https://github.com/WebGoat/WebGoat) and an official [homepage](https://www.owasp.org/index.php/Category:OWASP_WebGoat_Project).

This guide shows how to run WebGoat 8 container version on Azure Container Instances and apply security tasks and processes in the CI/CD pipeline.

## Prerequisites

* **An Azure subscription**. To create a free account go [here](https://azure.microsoft.com/en-gb/free/?utm_source=jeliknes&utm_medium=blog&utm_campaign=storage&WT.mc_id=storage-blog-jeliknes)
* **Azure Command Line (Azure CLI)** installed on your machine. To install go [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* **Azure DevOps account**. To create account follow [here](https://azure.microsoft.com/en-in/services/devops/pipelines/)
* **Github account**. To join Github go [here](https://github.com/join)

## Create Azure DevOps project and prepare WebGoat source code

In Azure DevOps create the new project

![](https://githubpictures.blob.core.windows.net/webgoataci/CreateProject.png)

Clone WebGoat project to newly created project from the Github repository: https://github.com/WebGoat/WebGoat.git
Go to Repos from menu and choose `or import a repository`

![](https://githubpictures.blob.core.windows.net/webgoataci/ImportProject.png)

When source code is imported to Azure Repos fix the Dockerfile with the proper WebGoat version's snapshot. To find the current snapshot version open `pom.xml` file located in the root directory and find line `<version>v8.0.0.M25</version>` (currently line is number 9 and Snapshot version is M25). After checking the proper version go to the directory webgoat-server and edit Dockerfile by replacing in line `ARG webgoat_version=v8.0.0-SNAPSHOT` SNAPSHOT to M25 (or other version pointed in pom.xml) so it should be `ARG webgoat_version=v8.0.0.M25`

## Create Azure container registry and Azure Key Vault

Create an Azure container registry (ACR) to store WebGoat docker containers using Azure CLI. More information about ACR is [here](https://docs.microsoft.com/en-us/azure/container-registry/)

Create Resource Group where all resources, including ACR will be located:
`az group create --name webGoatRG --location westeurope`

Create a container registry with admin user enabled:
`az acr create --resource-group webGoatRG --name acrWebGoat --sku Basic --admin-enabled true --location westeurope`

Create a Key Vault for storing sensitive keys and passwords like ACR username and password.
`az keyvault create --name "webGoatKV" --resource-group "webGoatRG" --location westeurope`

Open Key Vault and add ACR username and password as values:
* acrUsername - get ACR username from Access Keys tab in Azure portal
* acrPassword - get ACR password from Access Keys tab in Azure portal

## Configure CI/CD pipeline for Webgoat

### Configure Build pipeline

Now it is time to create Build pipeline. Go `Pipelines -> Builds` and choose `+New -> New Build Pipeline`. Select `Use the classic editor to create a pipeline without YAML.` on bottom of the page.
You will get:

![](https://githubpictures.blob.core.windows.net/webgoataci/SelectRepositoryBuild.png)

Proceed and select `Or start with an Empty job` under Select a template.

For build pipeline select `Agent pool -> Azure Pipelines` and `Agent Specification -> ubuntu-16.04` as WebGoat is based on Java.

![](https://githubpictures.blob.core.windows.net/webgoataci/UbuntuPool.png)

Now it is time to add tasks for building the code. There will be 2 tasks:

* **Maven** - builds WebGoat code 
* **Container task** - builds and pushes contaner to ACI

Add the task and in the search find Maven. Add the task and configure it like in the screenshot:

![](https://githubpictures.blob.core.windows.net/webgoataci/ConfigureMaven.png)

Configure also advanced settings as it is important to point JDK version and Maven settings, otherwise build will fail:

![](https://githubpictures.blob.core.windows.net/webgoataci/MavenDetails.png)

Add the next task, search for Docker and configure as it shown below:

![](https://githubpictures.blob.core.windows.net/webgoataci/BuildPushContainer.png)

Build pipeline is ready. Save it and queue to ensure that code compiles and image is pushed to configured ACI. You should see images tagged with the BuildId and Latest. Next step is to make the release pipeline.

### Configure the release pipeline

The release pipeline is simple since it contains only one step: create ACI and deploy image from ACR. 
Go to `Pipelines -> Releases` and choose `+New -> New release pipeline`.
Then select proper artifact, which is the latest build.

![](https://githubpictures.blob.core.windows.net/webgoataci/ReleasePipeline.png)

Create DevEnv stage. You can leave the default agent pool and agent specification (vs2017-win2016) since there will be only one task.
Add the task from tasks list. Select Azure CLI. We will run Azure CLI 

`az container create --resource-group $(resourceGroup) --name $(containerGroup) --image $(acrRegistry)/$(imageRepository):$(Build.BuildId) --dns-name-label $(containerDNS) --ports 8080 --registry-username $(acrUsername) --registry-password $(acrPassword)`.

There is no Azure ACI task you can do this thru the command line.

![](https://githubpictures.blob.core.windows.net/webgoataci/DeployContainerToAci.png)

Save the release pipeline and go to release pipeline's variables. Link Azure Keyvault under `Variable groups` to get ACR username and password. Non sensitive variables add under `Pipeline variables`:

* **resourceGroup** - Resource Group where ACI shall be deployed
* **containerGroup** - Container group name
* **containerDNS** - Contaner DNS label shall be unique
* **acrRegistry** - The ACR address
* **imageRepository** - Image repository

All is ready for the release. Save and create the release. After Release is run you should get container deployed in ACI.
Check the WebGoat solution by the address: `http://ACI_FQDN:8080/WebGoat`

**Enjoy learning security issues with WebGoat solution!**


