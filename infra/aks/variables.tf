# Variables
variable "aks_name" {}
variable "aks_rg_name" {}
variable "location" {}
variable "acr_rg_name" {}
variable "acr_name" {}
variable "network_rg_name" {}
variable "vnet_name" {}
variable "subnet_name" {}
variable "node_count" {
  default = 1
}
variable "node_vm_size" {
  default = "Standard_B2ms"
}
variable "dns_prefix" {
  default = "atcdns"
}
variable "aks_k8s_version" {
  default = "1.26.3"
}
variable "aks_sku_tier" {
  default = "Free"
}
variable "aks_law_name" {}