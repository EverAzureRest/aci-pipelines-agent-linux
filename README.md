# aci-pipelines-agent-linux

Azure DevOps Pipelines Self-Hosted Linux Agent in Azure Container Instance with basic private VNET connectivity

Reference Article: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux

## About

This project will build a docker container for an Azure Pipelines Self-Hosted Linux Agent which can be deployed to Azure Container Instances in a private VNET using the provided template.

## How to use

Build the dockerfile in the ./docker folder and push it to a container registry.

If Azure-Cli is installed and you are using an Azure Container Registry, from the docker folder run ```az acr build -t <registryserver.fqdn/imagename:tag> -r <registryuser> .```
This will build and push the image directly to the registry.

These templates assume Admin is enabled on the ACR registry or you have a direct login to your registry.  The given parameters file assumes using Azure Keyvault to store the secrets for both the Registry login and the AzureDevops PAT.  

A subnet in a VNET needs to be delegated to the Azure Container Instance service for the VNET integration to work.  This can be done via the subnet view in the Portal, or any other method, but the subnet must be empty, so I recommend creating a new subnet in an existing VNET, or an entirely new VNET.  /

This deployment also assumes you have a VNET and Subnet already defined.

To deploy the agent container to Azure, from the root of the project run: ```az deployment group create -n <deploymentName> -g <resourceGroup> --template-file ./azuredeploy.json --parameters ./yourparametersfile.json```

### To Do

Windows Version awaiting VNET integration for Windows Containers