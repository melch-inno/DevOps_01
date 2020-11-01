variable "rg_name" {
  description = "The name of the resource group in which the resources are created"
  default     = "{{user `managed_group`}}"
}

variable "manageddiskname" {
    description = "This descibes the image name of the disk"
    default     = "{{user `manageddisk_name`}}"
}

variable "subscriptionid" {
    description = "The location where resources are created"
    default = "{{env `ARM_SUBSCRIPTION_ID`}}"
}

variable "clientid" {
    description = "The ID of the client"
    default     = "{{user `client_id`}}"
}

variable "clientsecret" {
    description = "The client secret"
    default     = "{{user `client_secret`}}"
}

variable "tenantid" {
    description = "The ID of the tenant"
    default     = "{{user `tenant_id`}}"
}

variable "location" {
    description = "The location where resources are created"
    default     = "East US"
}

