# ATC Project

## Overview
This project contains the infrastructure and application code for deploying a static web application on Azure Kubernetes Service (AKS).

## Directory Structure
- `app/`: Contains the static application code.
- `infra/`: Contains the infrastructure code.

## Infrastructure
The infrastructure code is written using Terraform and the application code is written in HTML

## Prerequisites
- Terraform
- Azure CLI
- kubectl
- docker

## Deployment
1. Clone the repository.
2. Navigate to the `infra/` directory.
3. Initialize the Terraform directory:
```bash
terraform init
```
4. Apply the Terraform configuration:
```bash
terraform apply
```
5. Navigate to the `app/` directory.
6. Build the Docker Image:
```bash
docker build -t <your-acr-name>.azurecr.io/static-app:latest .
```
7. Push the DockerImage to ACR:
```bash
docker push <your-acr-name>.azurecr.io/static-app:latest
```
8. Deploy the application to AKS:
```bash
kubectl apply -f staticapp.yaml
```

## Application
The application is a simple web page that displays a message.
http://135.234.235.109

## Author
- [Bharath Suruneni]
