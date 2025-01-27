data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.aks_rg_name
  location = var.location
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.aks_law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurerm_subnet" "aks_subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.network_rg_name
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_rg_name
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                             = var.aks_name
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  dns_prefix                       = var.dns_prefix
  kubernetes_version               = var.aks_k8s_version
  sku_tier                         = var.aks_sku_tier
  node_resource_group              = "MC_${var.aks_rg_name}"
  http_application_routing_enabled = true

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = data.azurerm_subnet.aks_subnet.id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin = "azure"
    network_mode   = "transparent"
    network_policy = "calico"
  }
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  monitor_metrics {
    annotations_allowed = "prometheus.io/scrape,prometheus.io/path,prometheus.io/port"
    labels_allowed      = "app,component,environment"
  }
}

# Role assignment for AKS to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Add Data Collection Rule
resource "azurerm_monitor_workspace" "amw" {
  name                = "${var.aks_name}-prometheus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_monitor_data_collection_rule" "prom-dcr" {
  name                = "${var.aks_name}-prom-dcr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.amw.id
      name               = "PrometheusMetrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["PrometheusMetrics"]
  }
}

# Data Collection Endpoint for Prometheus
resource "azurerm_monitor_data_collection_endpoint" "prom_dce" {
  name                          = "${var.aks_name}-prom-dce"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  kind                          = "Linux"
  public_network_access_enabled = false
  description                   = "Prometheus Data Collection Endpoint for AKS"
}

# Associate Data Collection Rule with AKS
resource "azurerm_monitor_data_collection_rule_association" "prom_dcr_association" {
  name                    = "${var.aks_name}-prom-dcr-association"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prom-dcr.id
  description             = "Association between AKS cluster and Prometheus DCR"
}

resource "azurerm_monitor_data_collection_rule_association" "prom_dce_association" {
  name                          = "configurationAccessEndpoint"
  target_resource_id            = azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id   = azurerm_monitor_data_collection_endpoint.prom_dce.id
  description                   = "Association between AKS cluster and Prometheus DCE"
}
