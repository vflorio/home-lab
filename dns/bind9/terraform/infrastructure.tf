resource "dns_a_record_set" "dns" {
  zone = "intranet.vflorio.com."
  name = "dns"
  addresses = [
    "192.168.1.150"
  ]
  ttl = 3600
}

resource "dns_a_record_set" "nas" {
  zone = "intranet.vflorio.com."
  name = "nas"
  addresses = [
    "192.168.1.151"
  ]
  ttl = 3600
}

resource "dns_a_record_set" "firewall" {
  zone = "intranet.vflorio.com."
  name = "firewall"
  addresses = [
    "192.168.1.152"
  ]
  ttl = 3600
}