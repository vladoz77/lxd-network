# Terraform-модуль `lxd_network`

Создаёт управляемый bridge-сеть в LXD (`lxdbr0` и аналоги) с настройкой NAT, DHCP и встроенного dnsmasq.

## Требования

| Компонент | Версия |
|-----------|--------|
| Terraform | >= 1.3 (нужны `optional()` с дефолтами) |
| Провайдер `terraform-lxd/lxd` | ~> 3.0 |
| LXD | с настроенным remote/доступом к API |

## Использование

```hcl
module "lxd_network" {
  source = "./modules/lxd_network"

  network = {
    name             = "k8sbr0"
    ipv4_address     = "10.10.10.1/24"
    ipv4_dhcp_ranges = "10.10.10.100-10.10.10.200"
    dns_domain       = "k8s.devhomelab.site"
    raw_dnsmasq      = <<-EOF
      server=/devhomelab.site/172.10.10.254
      no-poll
    EOF
  }
}
```

С дополнительными ключами LXD через `extra_config`:

```hcl
module "lxd_network" {
  source = "./modules/lxd_network"

  network = {
    name         = "k8sbr0"
    ipv4_address = "10.10.10.1/24"

    extra_config = {
      "bridge.mtu"    = "1450"   # сеть поверх туннеля/оверлея
      "ipv4.firewall" = "false"  # файрволом управляете сами (nftables, Docker на хосте)
      "dns.mode"      = "managed"
    }
  }
}
```

Значения в `extra_config` всегда строки (`"false"`, `"1450"`). Список доступных ключей:
[LXD: bridge network](https://documentation.ubuntu.com/lxd/en/latest/reference/network_bridge/).
Ключ из `extra_config` **перекрывает** одноимённый ключ из типизированных полей.

Минимальный вариант (всё остальное по умолчанию):

```hcl
module "lxd_network" {
  source  = "./modules/lxd_network"
  network = { name = "lxdbr0" }
}
```

## Входные переменные

Все параметры передаются одним объектом `network`.

| Поле | Тип | По умолчанию | Описание |
|------|-----|--------------|----------|
| `name` | `string` | — (обязательно) | Имя bridge-интерфейса |
| `ipv4_address` | `string` | `"auto"` | CIDR адреса bridge (`10.10.10.1/24`), `auto` или `none` |
| `ipv6_address` | `string` | `"none"` | IPv6 CIDR, `auto` или `none` |
| `nat` | `bool` | `true` | NAT для IPv4 (`ipv4.nat`) |
| `dhcp` | `bool` | `true` | DHCP-сервер на bridge (`ipv4.dhcp`) |
| `ipv4_dhcp_ranges` | `string` | `null` | Диапазон DHCP, `start-end`. Если не задан — весь subnet |
| `dns_domain` | `string` | `"lxd"` | Домен для dnsmasq (`dns.domain`) |
| `dns_search` | `string` | `null` | Search-список; если не задан, LXD берёт `dns_domain` |
| `raw_dnsmasq` | `string` | `null` | Дополнительные строки конфигурации dnsmasq |
| `description` | `string` | `"Managed by Terraform"` | Описание сети |
| `extra_config` | `map(string)` | `{}` | Любые другие ключи LXD (`ipv4.firewall`, `bridge.mtu`, ...) |

Пустые и `null` значения в конфиг LXD **не передаются** — используются дефолты самого LXD.

## Выходные значения

| Output | Описание |
|--------|----------|
| `network_name` | Имя созданной сети |
| `ipv4_address` | Адрес bridge с маской (он же шлюз для инстансов), как задан |
| `ipv4_network_cidr` | CIDR самой подсети (`10.10.10.0/24`); `null` для `auto`/`none` |

## Заметки

- **NAT** работает только при заданном IPv4-адресе (не `none`).
- Изменение `raw_dnsmasq` перезапускает dnsmasq сети — DHCP/DNS кратковременно недоступны.
- `ipv4_dhcp_ranges` должен лежать внутри подсети `ipv4_address` и не пересекаться со статическими адресами.
- Для статических IP в инстансах держите их вне DHCP-диапазона.