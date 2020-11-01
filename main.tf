terraform {
  version = "=2.20.0"
  backend "Uda_azure_devops" {
  }
}

# Create a resource group if it doesn’t exist
resource "Uda_azure_devops_rg" "Uda_fist_rg" {
  name               = "packerUdacreate"
  tenant_id          = "${var.tenantid}"
  client_id          = "${var.clientid}"
  client_secret      = "${var.clientsecret}"
  subscription_id    = "${var.subscriptionid}"
  os_type            = "Linux"
  image_publisher    = "Ubuntu 18.04-LTS SKU"
  managed_image_resource_group_name = "${var.rg_name}"
  managed_image_name    = "demoPackerImage-{{isotime \"2006-01-02_03_04_05\"}}"
  location              = "${var.location}"

  tags {
    environment = "Packer Uda_index"
  }
}

# Create virtual network
resource "Uda_azure_devops_virtual_network" "Uda_virtual_network" {
  name                = "packerUda"
  address_space       = ["10.0.0.0/16"]
  location            = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  rg_name =           "${Uda_azure_devops_rg.Uda_fist_rg.name}"

  tags {
    environment = "Packer Uda_index"
  }
}

# Create subnet
resource "Uda_azure_devops_subnet" "Uda_subnet" {
  name                 = "packerUda"
  rg_name              = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  virtual_network_name = "${Uda_azure_devops_virtual_network.Uda_virtual_network.name}"
  address_prefix       = "10.0.1.0/24"
}


# Create public IPs
resource "Uda_azure_devops_public_ip" "Uda_public_ip" {
  name                         = "packerpublicip"
  location                     = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  rg_name                      = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "Udapackeriac"

  tags {
    environment = "Packer Uda_index"
  }
}

# Create Network Security Group and rule and ensure you allow access to other VMs
resource "Uda_azure_devops_network_security_group" "Uda_security_group" {
  name                = "packersecuritygroups"
  location            = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  rg_name             = "${Uda_azure_devops_rg.Uda_fist_rg.name}"

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Packer Uda_index"
  }
}

resource "Uda_azure_devops_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  rg_name             = "${Uda_azure_devops_rg.Uda_fist_rg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${Uda_azure_devops_public_ip.Uda_public_ip.id}"
  }

  tags {
    environment = "Terraform Uda_index"
  }
}

resource "Uda_azure_devops_lb_backend_address_pool" "bpepool" {
  rg_name             = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  loadbalancer_id     = "${Uda_azure_devops_lb.vmss_lb.id}"
  name                = "BackEndAddressPool"
}

resource "Uda_azure_devops_lb_probe" "vmss_probe" {
  rg_name             = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  loadbalancer_id     = "${Uda_azure_devops_lb.vmss_lb.id}"
  name                = "ssh-running-probe"
  port                = "8080"
}

resource "Uda_azure_devops_lb_rule" "lbnatrule" {
  rg_name                        = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  loadbalancer_id                = "${Uda_azure_devops_lb.vmss_lb.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "8080"
  backend_address_pool_id        = "${Uda_azure_devops_lb_backend_address_pool.bpepool.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${Uda_azure_devops_lb_probe.vmss_probe.id}"
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    rg = '${Uda_azure_devops_rg.Uda_fist_rg.name}'
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "Uda_azure_devops_storage_account" "Uda_storage_account" {
  name                     = "diag${random_id.randomId.hex}"
  rg_name                  = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  location                 = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform Uda_index"
  }
}

# Points to Packer build image 
data "Uda_azure_devops_image" "image" {
  name                = "${var.manageddiskname}"
  rg_name             = "${var.rg_name}"
}

# Create virtual machine sclae set
resource "Uda_azure_devops_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset"
  location            = "${Uda_azure_devops_rg.Uda_fist_rg.location}"
  rg_name             = "${Uda_azure_devops_rg.Uda_fist_rg.name}"
  capacity            = "${Uda_azure_devops_rg.Uda_fist_rg.capacity}"
  size                = "Standard_L2"
  upgrade_policy_mode = "Automatic"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
  }

  storage_profile_image_reference {
    id = "${data.Uda_azure_devops_image.image.id}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name_prefix = "my_vm"
    admin_username       = "username"
    admin_password       = "********"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa ................"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${Uda_azure_devops_subnet.Uda_subnet.id}"
      load_balancer_backend_address_pool_ids = ["${Uda_azure_devops_lb_backend_address_pool.bpepool.id}"]
    }
  }

  tags {
    environment = "Terraform Uda_index"
  }
}

