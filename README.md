# Implement Security in Azure DevOps CI/CD

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

Build pipeline is ready. Save it and queue to ensure that code compiles and image is pushed to configured ACI.

* **Build** - builds and pushes WebGoat container to the ACR
* **DeployToDev** - deploys pushed container from ACR to ACI. The first time running also creates ACI

CI/CD pipeline requires an access to ACR to be able to push containers and an access to Resource Group at least to create ACI. To allow this create 2 service connections.

Create Service connection for ACR by going `Project settings` and under Pipelines choose `Service connections` and `New service connection`. Choose `Docker Registry` and fill required lines under `Azure Container Registry`

![](https://githubpictures.blob.core.windows.net/webgoataci/acrConnection.png)

Create Service connection for subscription by choosing `Azure Resource Manager` service connection. Choose proper subscription and resource group.

![](https://githubpictures.blob.core.windows.net/webgoataci/subscConnection.png)

Open `azure-pipelines.yml` and replace variables with proper values:

* **dockerRegistryServiceConnection** - Connection name for ACR
* **resourceGroup** - Azure Resource Group where resources are located
* **acrRegistry** - FQDN name for ACR Registry (for example: acrwebgoat.azurecr.io)
* **subscriptionConnection** - Connection name for Azure subscription
* **containerGroup** - Container group name
* **containerDNS** - Contaner DNS label shall be unique
  
Add created Key Vault to Azure DevOps Project by creating new Variable group `acrDetails` under `Pipelines -> Library`.

Link to Key Vault and add required variables.

![](https://githubpictures.blob.core.windows.net/webgoataci/linkAKV.png)

![](https://githubpictures.blob.core.windows.net/webgoataci/getAKV.png)

Go to `Pipelines` and check that pipeline has been automatically created. The first time it can fail and require manual authorization.

![](https://githubpictures.blob.core.windows.net/webgoataci/authorize.png)

Authorize and Run pipeline. It will take some time for Maven task, but after it should create and deploy container to ACR and publish it to ACI. 

![](https://githubpictures.blob.core.windows.net/webgoataci/build.png)


**Enjoy learning security issues with WebGoat solution.**
