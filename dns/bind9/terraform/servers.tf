# Server Gateway
#
# All *.<server> wildcards point to the gateway: Traefik is the only reverse proxy,
# apps on the other servers are published to it through traefik-kop

resource "dns_a_record_set" "gateway" {
  zone      = "intranet.vflorio.com."
  name      = "gateway"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}

resource "dns_a_record_set" "gateway_wildcard" {
  zone      = "intranet.vflorio.com."
  name      = "*.gateway"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}

# Server Prod 1

resource "dns_a_record_set" "management" {
  zone      = "intranet.vflorio.com."
  name      = "management"
  addresses = ["192.168.1.191"]
  ttl       = 3600
}

resource "dns_a_record_set" "management_wildcard" {
  zone      = "intranet.vflorio.com."
  name      = "*.management"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}

# Server Media 

resource "dns_a_record_set" "media" {
  zone      = "intranet.vflorio.com."
  name      = "media"
  addresses = ["192.168.1.192"]
  ttl       = 3600
}

resource "dns_a_record_set" "media_wildcard" {
  zone      = "intranet.vflorio.com."
  name      = "*.media"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}

# Server Dev 

resource "dns_a_record_set" "dev" {
  zone      = "intranet.vflorio.com."
  name      = "dev"
  addresses = ["192.168.1.193"]
  ttl       = 3600
}

resource "dns_a_record_set" "dev_wildcard" {
  zone      = "intranet.vflorio.com."
  name      = "*.dev"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}

# Server Cloud 

resource "dns_a_record_set" "cloud" {
  zone      = "intranet.vflorio.com."
  name      = "cloud"
  addresses = ["192.168.1.194"]
  ttl       = 3600
}

resource "dns_a_record_set" "cloud_wildcard" {
  zone      = "intranet.vflorio.com."
  name      = "*.cloud"
  addresses = ["192.168.1.190"]
  ttl       = 3600
}
