output "network_name" {
  description = "Имя созданной сети"
  value       = lxd_network.network.name
}

output "ipv4_address" {
  description = "Адрес bridge (шлюз) с маской"
  value       = var.network.ipv4_address
}

output "ipv4_network_cidr" {
  description = "CIDR подсети; null для auto/none"
  value       = try(cidrsubnet(var.network.ipv4_address, 0, 0), null)
}