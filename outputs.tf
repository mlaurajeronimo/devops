output "cluster_name" {
  description = "Nome do cluster Kind criado"
  value       = kind_cluster.devops.name
}

output "client_certificate" {
  description = "Certificado de cliente do cluster (sensível)"
  value       = kind_cluster.devops.client_certificate
  sensitive   = true
}

output "endpoint" {
  description = "Endpoint da API do cluster Kubernetes"
  value       = kind_cluster.devops.endpoint
}

output "kubeconfig_path" {
  description = "Caminho do arquivo kubeconfig gerado pelo Kind"
  value       = kind_cluster.devops.kubeconfig_path
}
