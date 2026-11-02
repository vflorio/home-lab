# Cloudflare DNS
# ---
# Templates to manage DNS Records on Cloudflare
#
# Nothing is published on the internet: every app is reachable only from the LAN and
# the tailnet through *.<server>.intranet.vflorio.com. The Cloudflare zone is also
# used by Traefik for the Let's Encrypt DNS-01 challenge.
#
# Intranet records are mirrored from bind9 (dns/bind9/terraform) with their private
# LAN IPs, so any resolver (bind9, Cloudflare, Google) gives the same answer: LAN
# clients that can't use bind9 (e.g. TVs, or when the server is off) still resolve
# them. Keep them in sync with servers.tf and infrastructure.tf there. Personal
# devices (hardware.tf, activasticks.tf) stay on bind9 only.
#
# To expose an app later, prefer a Cloudflare Tunnel (no port forward, no public IP)
# and add its name here as a CNAME to the tunnel instead of an AAAA to the home IPv6.
# See docs/networking.md

locals {
    apps = {}

    records = toset(flatten(values(local.apps)))

    gateway_ip = "192.168.1.190"

    intranet = {
        # Infrastructure
        "dns"      = "192.168.1.150"
        "nas"      = "192.168.1.151"
        "firewall" = "192.168.1.152"

        # Servers: all *.<server> wildcards point to the gateway (Traefik)
        "gateway"      = local.gateway_ip
        "*.gateway"    = local.gateway_ip
        "management"   = "192.168.1.191"
        "*.management" = local.gateway_ip
        "media"        = "192.168.1.192"
        "*.media"      = local.gateway_ip
        "dev"          = "192.168.1.193"
        "*.dev"        = local.gateway_ip
        "cloud"        = "192.168.1.194"
        "*.cloud"      = local.gateway_ip
    }
}

resource "cloudflare_record" "app" {
    for_each = local.records

    name = each.value
    type = "AAAA"
    zone_id = var.cloudflare_zone_id
    content = var.public_ipv6
    proxied = true
}

resource "cloudflare_record" "intranet" {
    for_each = local.intranet

    name = "${each.key}.intranet"
    type = "A"
    zone_id = var.cloudflare_zone_id
    content = each.value
    proxied = false
    ttl = 3600
}

# Email
#
# The domain sends and receives no mail: null MX (RFC 7505), SPF/DMARC/DKIM that
# reject everything, so nobody can spoof @vflorio.com

resource "cloudflare_record" "null_mx" {
    name = "@"
    type = "MX"
    zone_id = var.cloudflare_zone_id
    content = "."
    priority = 0
    ttl = 3600
}

resource "cloudflare_record" "spf" {
    name = "@"
    type = "TXT"
    zone_id = var.cloudflare_zone_id
    content = "\"v=spf1 -all\""
    ttl = 3600
}

resource "cloudflare_record" "dmarc" {
    name = "_dmarc"
    type = "TXT"
    zone_id = var.cloudflare_zone_id
    content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""
    ttl = 3600
}

resource "cloudflare_record" "dkim" {
    name = "*._domainkey"
    type = "TXT"
    zone_id = var.cloudflare_zone_id
    content = "\"v=DKIM1; p=\""
    ttl = 3600
}

# CAA
#
# Only Let's Encrypt (Traefik DNS-01) may issue certificates. Cloudflare adds the CAA
# records for its own Universal SSL CAs automatically

resource "cloudflare_record" "caa" {
    for_each = toset(["issue", "issuewild"])

    name = "@"
    type = "CAA"
    zone_id = var.cloudflare_zone_id
    ttl = 3600

    data {
        flags = 0
        tag = each.value
        value = "letsencrypt.org"
    }
}
