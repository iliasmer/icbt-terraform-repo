# ICBT ML Thesis – Cloud Deployment (Azure)

## Overview
This project deploys a small Azure environment via Terraform to run and benchmark ML workloads (using BentoML) for a thesis comparing **on-premise vs cloud** deployment.


## Prerequisites
* Azure subscription (free trial is fine)
* Azure CLI installed
* Terraform >= 1.10
* WSL or Linux terminal


## Steps

### 1. Authenticate to Azure
```bash
az login --use-device-code
```

If you have multiple subscriptions:

```bash
az account set --subscription "<subscription-id>"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Deploy Infrastructure

```bash
terraform apply -auto-approve
```

### 4. Get the VM’s Public IP

```bash
az vm list-ip-addresses --resource-group rg-ml-thesis --name vm-ml-thesis --output table
```

Example output:
```
VirtualMachine    PublicIPAddresses    PrivateIPAddresses
----------------  -------------------  --------------------
vm-ml-thesis      51.12.95.76          10.10.1.4
```

### 5. Connect via SSH (with auto-generated key)

Terraform automatically generates a private SSH key (`id_rsa_auto.pem`) in the `terraform/` folder.

On Windows/WSL, SSH refuses to use keys stored on `/mnt/c/...` due to permission rules.
To connect, copy the key to your Linux home directory:

```bash
mkdir -p ~/.ssh/ml-thesis
cp terraform/id_rsa_auto.pem ~/.ssh/ml-thesis/
chmod 600 ~/.ssh/ml-thesis/id_rsa_auto.pem
```

Then connect:
```bash
ssh -i ~/.ssh/ml-thesis/id_rsa_auto.pem kth_admin@51.12.95.76 <-- public IP 
```

You should see:

```
kth_admin@vm-ml-thesis:~$
```

When finished:

```bash
exit
```

You can safely delete the copied key anytime:

```bash
rm ~/.ssh/ml-thesis/id_rsa_auto.pem
```
