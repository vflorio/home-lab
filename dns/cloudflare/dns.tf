# Cloudflare DNS
# ---
# Templates to manage DNS Records on Cloudflare
#
# Nothing is published on the internet: every app is reachable only from the LAN and
# the tailnet through *.<server>.intranet.vflorio.com (bind9). The Cloudflare zone is
# still used by Traefik for the Let's Encrypt DNS-01 challenge.
#
# To expose an app later, prefer a Cloudflare Tunnel (no port forward, no public IP)
# and add its name here as a CNAME to the tunnel instead of an AAAA to the home IPv6.
# See docs/networking.md

locals {
    apps = {}

    records = toset(flatten(values(local.apps)))
}

resource "cloudflare_record" "app" {
    for_each = local.records

    name = each.value
    type = "AAAA"
    zone_id = var.cloudflare_zone_id
    content = var.public_ipv6
    proxied = true
}
