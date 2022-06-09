# aci-pipelines-agent-linux

Azure DevOps Pipelines Self-Hosted Linux Agent in Azure Container Instance with basic private VNET connectivity

Reference Article: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux

## About

This project will build a docker container for an Azure DevOps Pipelines Self-Hosted Linux Agent which can be deployed to Azure Container Instances in a private VNET using the provided template.

This allows you to manage and update your Self Hosted agents as a set of ephimeral compute, yet can still reach inside the VNET to utilize internal pipeline integrations.  

## How to use

Issue a Azure DevOps PAT by following this article: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows 

Copy the PAT and save it in an Azure KeyVault as a Secret:
```bash
az keyvault secret set -n <secretName> --vault-name <keyVault Name> --value <PAT token value>
```
Make sure you denote the Key Vault Secret Name as it will be used as a parameter in the template deployment

Note: <b>Ensure your PAT has access to write agent pools</b>

The included Bicep template will build a container registry and a container image based on the published DOCKERFILE in this repository. It will automatically push the image to the container registry. 

A subnet in a VNET needs to be delegated to the Azure Container Instance service for the VNET integration to work.  The template assumes you have a VNET already.  It will create a subnet to delegate the Container Instance service the correct permissions so the VNET integration will work.  You can reference an existing subnet as well.

To deploy the agent containers to Azure, from the root of the project run: 
```bash
az deployment group create -n <deploymentName> -g <resourceGroup> --template-file ./main.bicep --parameters ./yourparametersfile.json
```
An example parameters file is included in this repository

### To Do

Windows Version awaiting VNET integration for Windows Containers