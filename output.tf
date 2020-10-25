
output "vm_ip" {
    value = "${Uda_azure_devops_public_ip.Uda_public_ip.ip_address}"
}

output "vm_dns" {
    value = "http://${Uda_fist_rg_public_ip.Uda_public_ip.domain_name_label}.eastus.cloudapp.azure.com"
}