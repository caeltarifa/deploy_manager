# Azure IoT Hub & IoT Edge Terraform Provisioner

## Purpose

Automates deployment of Azure IoT Hub, IoT edge Device Provisioning and enrollment, using Terraform and Azure CLI.

## Pattern

- **Modular**: Separate modules for IoT Hub, DPS, and enrollment.
- **Loose Coupling**: Modules share outputs/variables, not data sources.
- **CLI Integration**: Device enrollment via Azure CLI in a `null_resource`.

## Usage

1. **Prerequisites**
   - Terraform & Terraformer  
     ```sh
     pyinfra @local configurator/deploy/terraform_installation.py
     ```
   - Azure CLI auth & Azure subscription
      ```sh
      az login
      az account set --subscription <your-subscription-id>
      ```
   - Download `.env_provisioner` file

2. **Configure**  
   - Set variables in `.env_provisioner`
   - Target IoT Edge device names in `<device-client-list>.tfvars`

3. **Import Existing IoT Hub**  
   Track the state of existing IoT Hub into Terraform state **from the `Provisioner` directory**:
   ```sh
   terraform import 'module.iothub.azurerm_iothub.prod_iothub' '/subscriptions/<idsubscription>/resourceGroups/<resource-group>/providers/Microsoft.Devices/iotHubs/<iothub-name>'
   ```
4. **TODO: Recovery strategy into cloud-org-backup/**
   ```sh
   mkdir -p ~/.terraform.d/plugins/linux_amd64
   terraformer import azure --resources iothub --resource-group akira-production-rg --filter="Name=AkiraHubProd"
   
   cp .terraform/providers/registry.terraform.io/hashicorp/azurerm/4.47.0/linux_amd64/terraform-provider-azurerm_v4.47.0_x5 ~/.terraform.d/plugins/linux_amd64/terraform-provider-azurerm

   chmod +x ~/.terraform.d/plugins/linux_amd64/terraform-provider-azurerm

   terraformer import azure --resources=iothub --resource-group=<ressource-group>
   ```

5. **Run**
   ```sh
   export $(grep -v '^#' .env_provisioner | xargs)
   terraform init
   terraform plan -var-file="<device-client-list>.tfvars" -out="tfplan_production_$(date +%F-%H%M)"
   terraform apply tfplan_production_<datetime>
   ```

6. **Destroy**
   ```sh
   terraform destroy -var-file