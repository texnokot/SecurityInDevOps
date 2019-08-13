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
  - [Whitesource Bolt: check open source components](#whitesource-bolt-check-open-source-components)
  - [Get rid off credentials from the code](#get-rid-off-credentials-from-the-code)
  - [Scan containers for the security and complaince](#scan-containers-for-the-security-and-complaince)

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

## Whitesource Bolt: check open source components

Development in todays world includes usage of 3rd party components. It is important to check their security state and licensing. The way how it can be done is to add security check in Build pipeline.

One of the solution is free extension for Azure DevOps: **WhiteSource Bolt**.

WhiteSource Bolt scans all your projects and detects open source components, their license and known vulnerabilities. Not to mention, it also provide fixes.

Extension is available at Azure DevOps Marketplace. If it is already not installed on the organization go to the [Marketplace](https://marketplace.visualstudio.com/items?itemName=whitesource.ws-bolt) and follow WhiteSource Bolt installation instructions. After install it is available as a task.
Next step is to add the task in `Build pipeline`. You can start with defaults:

![](https://githubpictures.blob.core.windows.net/webgoataci/WhitesourceBolt.png)

Add the task and run Build pipeline. After the run you will see additional Tab under Build run. Open it and explore findings:

![](https://githubpictures.blob.core.windows.net/webgoataci/WhiteSourceBoltResults.png)

WhiteSource Bolt is also available under `Pipelines` as a separate tab. There you can see Monitored Build definitions and export reports in 4 formats: JSON, Excel, Pdf and HTML.

## Get rid off credentials from the code

It is well known that having credentials hardcoded in the code is not good security practice. To avoid this situation, you can implement credential scanning already in the build process when code is pushed to the repository.

There are different techniques and tools for that. One of them is provided by Microsoft and is part of bigger extension **Microsoft Security Code Analysis**.

The Microsoft Security Code Analysis Extension is a collection of tasks for the Azure DevOps Services platform. These tasks automatically download and run secure development tools in the build pipeline. The extension is now in a Private Preview (by invitation). Extension contains different tasks focused on security checks:

* **Credential Scanner** for checking secrets in the code
* **BinSkim** is a Portable Executable (PE) light-weight scanner that validates compiler/linker settings
* **TSLint** is an extensible static analysis tool that checks TypeScript code
* **Roslyn Analyzers** is compiler-integrated static analysis tool for analyzing managed code (C# and VB)
* **Security Risk Detection** is Microsoft's unique cloud-based fuzz testing service for identifying exploitable security bugs in software
* **Anti-Malware Scanner** it runs on build agent which has Windows Defender installed.

To get an access to extensions you need sign up for preview. Follow the [link](https://secdevtools.azurewebsites.net/).

We will add Credential Scanner in the build pipeline. 

Since the build pipeline runs on Ubuntu agent and Credential Scanner's task works only on Windows platform you need to add another agent job. Add agent job under pipeline and select agent specification `vs2017-win2016`.

There will be two agent jobs. Place CredScan's job as the first one. Add `CredScan` task, you can leave defaults. CredScan allows different output formats: SARIF, PREfast, TSV, CVS. CredScan also writes findings in the Log console. After adding the task you should get following setup:

![](https://githubpictures.blob.core.windows.net/webgoataci/CredScan.png)

Run the build and check the logs. Look into CredScan task's logs. You should find some results.

![](https://githubpictures.blob.core.windows.net/webgoataci/CredScanResults.png)

## Scan containers for the security and complaince

Next step is to add security checks for images as they may contain security issues and configuration flaws. There are commercial scanners available as a service in Azure.

For this task we will use open source version of container complaince platform Anchore.

![https://anchore.com/opensource/](https://anchore.com/wp-content/uploads/2019/04/Anchore_Logo-300x95.png)

_The Anchore Engine allows developers to perform detailed analysis on their container images, run queries, produce reports and define policies that can be used in CI/CD pipelines. Developers can extend the tool to add new plugins that add new queries, new image analysis, and new policies._

More information about Anchore can be found at [their website](https://anchore.com/opensource/).

You need to install the solution and maintain it. [Follow the installation guide, which shows how to install Anchore server on AKS](https://anchore.com/azure-anchore-kubernetes-service-cluster-with-helm/)

Write down **public IP of Anchore, username and password**. Save them in created Azure KeyVault wallet and ensure that they are linked in the Build pipeline.

Install `anchore-cli` tool on your computer to be able to add your ACR registry in Anchore. Command for registering is:

`anchore-cli --u ANCHORE_USERNAME --p ANCHORE_PASSWORD --url http://ANCHORE_IP:8228/v1 registry add --registry-type docker_v2 ACR_URL ACR_ADMIN "ACR_PASSWORD"`

Add your image to Anchore, so it does Digest calculation. Anchore asks for image and tag, this is a reason why we also tagged images with latest. Run command:

`anchore-cli --u ANCHORE_USERNAME --p ANCHORE_PASSWORD --url http://ANCHORE_IP:8228/v1 image add ACR_URL/imageREPOSITORY:latest`

In the Build pipeline add the agent job with agent specification `ubuntu-16.04`. In the `Dependencies` select agen job, which is responsible for compiling and pushing WebGoat container to ACR. It is important to have that job finished before scans gets triggered as we want to scan the lates image.

![](https://githubpictures.blob.core.windows.net/devopsdayspost/ContainerSecurityJob.png)

Add the first task, which is reponsible for installing [anchore-cli](https://github.com/anchore/anchore-cli) tool on agent.

![](https://githubpictures.blob.core.windows.net/devopsdayspost/InstallanchoreStep.png)

Select `Bash` task and add inline command: `sudo pip install anchorecli`

After tool is installed we can run scans. There will be two scan tasks:

* **Vulnerability scanner** - task will scan for vulnerabilities in the image
* **Policy scanner** - task will scan for predefined security policies. It is possible to define custom or use predefined. Policies like, for example, container has service, which runs on 22 port and etc.

Add the vulnerability scanner by adding `Bash` task with inline command: `anchore-cli --json --url $(anchorServer) --u $(anchorUser) --p $(anchorPassword) image vuln $(acrRegistry)/$(imageRepository):latest os > image-vuln.json`

Command runs `anchore-cli`, which triggers Anchore engine to start the scan and publish results in image-vuln.json file.

![](https://githubpictures.blob.core.windows.net/devopsdayspost/AnchoreVulnerabilityScan.png)

Add the complaince scanner by adding `Bash` task with inline command: `anchore-cli --json --url $(anchorServer) --u $(anchorUser) --p $(anchorPassword) evaluate check $(acrRegistry)/$(imageRepository):latest --detail > image-policy.json`

![](https://githubpictures.blob.core.windows.net/devopsdayspost/AnchoreCompliance.png)

Both scan will produce json reports and we need to publish them as pipeline artifact, which can be downloaded after. To do this add two tasks:

![](https://githubpictures.blob.core.windows.net/devopsdayspost/CopyFilesReportsAnchore.png)

![](https://githubpictures.blob.core.windows.net/devopsdayspost/PublishArtifactsAnchore.png)

Run the build pipeline and after the run check for published Artifacts:

![](https://githubpictures.blob.core.windows.net/devopsdayspost/AnchoreArtifacts.png)

Download and explore the findings.


TODO: add instructions for AzSk and summary.
