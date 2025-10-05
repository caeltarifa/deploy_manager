# Azure IoT Hub & DPS Terraform Provisioner

## Purpose

Automates deployment of Azure IoT Hub, Device Provisioning Service (DPS), and device enrollment using Terraform and Azure CLI.

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
   - Azure CLI & Azure subscription

2. **Configure**  
   - Set variables in `.env_provisioner`
   - Target IoT Edge device names in `terraform.tfvars`

3. **Authenticate**
   ```sh
   az login
   az account set --subscription <your-subscription-id>
   ```

4. **Import Existing IoT Hub**  
   Track the state of existing IoT Hub into Terraform state **from the `Provisioner` directory**:
   ```sh
   terraformer import azure --resources iothub --resource-group akira-production-rg --filter="Name=AkiraHubProd"
   
   terraform import 'module.iothub.azurerm_iothub.prod_iothub' '/subscriptions/<idsubscription>/resourceGroups/<resource-group>/providers/Microsoft.Devices/iotHubs/<iothub-name>'
   ```

5. **Run**
   ```sh
   export $(grep -v '^#' .env_provisioner | xargs)
   terraform init
   terraform plan -var-file="terraform.tfvars" -out="tfplan_production_<datetime>"
   terraform apply tfplan_production_<datetime>
   ```

6. **Destroy**
   ```sh
   terraform destroy -var-file