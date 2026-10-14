variable "network" {
  description = "Конфигурация LXD bridge-сети"
  type = object({
    name             = string
    ipv4_address     = optional(string, "auto")
    ipv6_address     = optional(string, "none")
    nat              = optional(bool, true)
    dhcp             = optional(bool, true)
    ipv4_dhcp_ranges = optional(string)
    dns_domain       = optional(string, "lxd")
    dns_search       = optional(string)
    raw_dnsmasq      = optional(string)
    description      = optional(string, "Managed by Terraform")
    extra_config     = optional(map(string), {})
  })

  validation {
    condition = (
      contains(["auto", "none"], var.network.ipv4_address) ||
      can(cidrhost(var.network.ipv4_address, 0))
    )
    error_message = "ipv4_address: ожидается CIDR (например 10.10.10.1/24), 'auto' или 'none'."
  }

  validation {
    condition = (
      var.network.ipv4_dhcp_ranges == null ||
      can(regex("^\\d{1,3}(\\.\\d{1,3}){3}-\\d{1,3}(\\.\\d{1,3}){3}$", var.network.ipv4_dhcp_ranges))
    )
    error_message = "ipv4_dhcp_ranges: ожидается формат 'start-end', например 10.10.10.100-10.10.10.200."
  }

  validation {
    condition     = !(var.network.nat && var.network.ipv4_address == "none")
    error_message = "NAT невозможен при ipv4_address = 'none'."
  }
}