terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/k3s-config"
}

resource "kubernetes_namespace" "mlops" {
  metadata {
    name = "mlops"
  }
}

resource "kubernetes_deployment" "house_price_api" {
  metadata {
    name      = "house-price-api"
    namespace = kubernetes_namespace.mlops.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "house-price-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "house-price-api"
        }
      }
      spec {
        container {
          image = "house-price-api:latest"
          name  = "house-price-api"
          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "house_price_api" {
  metadata {
    name      = "house-price-api-service"
    namespace = kubernetes_namespace.mlops.metadata[0].name
  }
  spec {
    selector = {
      app = "house-price-api"
    }
    port {
      port        = 8000
      target_port = 8000
    }
    type = "ClusterIP"
  }
}