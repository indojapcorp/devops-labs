terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/mydev/tuts/cloudtuts/k8sshared/k3s.yaml"  # Point to your k3s kubeconfig
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true  # Add this line to fix the error
  endpoints {
    s3 = "http://localhost:4566"  # LocalStack endpoint
  }
  s3_force_path_style         = true  # Ensure path-style URLs for LocalStack
}

# Namespace for Kafka
resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

# Kafka StatefulSet (single broker for your k3s cluster)
resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kafka"
      }
    }
    service_name = "kafka-svc"
    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }
      spec {
        container {
          name  = "kafka"
          image = "bitnami/kafka:latest"
          env {
            name  = "KAFKA_CFG_NODE_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_CFG_PROCESS_ROLES"
            value = "broker,controller"
          }
          env {
            name  = "KAFKA_CFG_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          }
          env {
            name  = "KAFKA_CFG_LISTENERS"
            value = "PLAINTEXT://:9092,CONTROLLER://:9093"
          }
          env {
            name  = "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
          }
          env {
            name  = "KAFKA_CFG_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka-svc.kafka.svc.cluster.local:9092"
          }
          env {
            name  = "KAFKA_CFG_BROKER_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS"
            value = "1@kafka-0.kafka-svc.kafka.svc.cluster.local:9093"
          }
          port {
            container_port = 9092
          }
          port {
            container_port = 9093
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1024Mi"
            }
          }
        }
      }
    }
  }
}

# Headless Service for Kafka
resource "kubernetes_service" "kafka_svc" {
  metadata {
    name      = "kafka-svc"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }
  spec {
    cluster_ip = "None"  # Headless service
    selector = {
      app = "kafka"
    }
    port {
      name        = "plaintext"  # Added required port name
      port        = 9092
      target_port = 9092
    }
    port {
      name        = "controller"  # Added required port name
      port        = 9093
      target_port = 9093
    }
  }
}

# S3 Bucket in LocalStack for Kafka data (simulation)
resource "aws_s3_bucket" "kafka_bucket" {
  bucket = "kafka-data-bucket"
}