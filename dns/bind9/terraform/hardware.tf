# Server fisico principale
resource "dns_a_record_set" "server" {
  zone      = "intranet.vflorio.com."
  name      = "server"
  addresses = ["192.168.1.1"]
  ttl       = 3600
}

resource "dns_a_record_set" "silicon" {
  zone      = "intranet.vflorio.com."
  name      = "silicon"
  addresses = ["192.168.1.1"]
  ttl       = 3600
}

# Workstation principale
resource "dns_a_record_set" "workstation" {
  zone      = "intranet.vflorio.com."
  name      = "workstation"
  addresses = ["192.168.1.2"]
  ttl       = 3600
}

resource "dns_a_record_set" "carbon" {
  zone      = "intranet.vflorio.com."
  name      = "carbon"
  addresses = ["192.168.1.2"]
  ttl       = 3600
}

# Mac Mini
resource "dns_a_record_set" "macmini" {
  zone      = "intranet.vflorio.com."
  name      = "macmini"
  addresses = ["192.168.1.3"]
  ttl       = 3600
}

resource "dns_a_record_set" "nitrogen" {
  zone      = "intranet.vflorio.com."
  name      = "nitrogen"
  addresses = ["192.168.1.3"]
  ttl       = 3600
}

# Tablet Android
resource "dns_a_record_set" "tablet-android" {
  zone      = "intranet.vflorio.com."
  name      = "tablet-android"
  addresses = ["192.168.1.4"]
  ttl       = 3600
}

resource "dns_a_record_set" "boron" {
  zone      = "intranet.vflorio.com."
  name      = "boron"
  addresses = ["192.168.1.4"]
  ttl       = 3600
}

# iPhone
resource "dns_a_record_set" "smartphone-ios" {
  zone      = "intranet.vflorio.com."
  name      = "smartphone-ios"
  addresses = ["192.168.1.5"]
  ttl       = 3600
}

resource "dns_a_record_set" "phosphorus" {
  zone      = "intranet.vflorio.com."
  name      = "phosphorus"
  addresses = ["192.168.1.5"]
  ttl       = 3600
}

# Smart TV Hisense
resource "dns_a_record_set" "tv-hisense" {
  zone      = "intranet.vflorio.com."
  name      = "tv-hisense"
  addresses = ["192.168.1.6"]
  ttl       = 3600
}

resource "dns_a_record_set" "sulfur" {
  zone      = "intranet.vflorio.com."
  name      = "sulfur"
  addresses = ["192.168.1.6"]
  ttl       = 3600
}

# Smart TV Android
resource "dns_a_record_set" "tv-android" {
  zone      = "intranet.vflorio.com."
  name      = "tv-android"
  addresses = ["192.168.1.7"]
  ttl       = 3600
}

resource "dns_a_record_set" "chlorine" {
  zone      = "intranet.vflorio.com."
  name      = "chlorine"
  addresses = ["192.168.1.7"]
  ttl       = 3600
}

# Laptop Discovery
resource "dns_a_record_set" "laptop-discovery" {
  zone      = "intranet.vflorio.com."
  name      = "laptop-discovery"
  addresses = ["192.168.1.8"]
  ttl       = 3600
}

resource "dns_a_record_set" "argon" {
  zone      = "intranet.vflorio.com."
  name      = "argon"
  addresses = ["192.168.1.8"]
  ttl       = 3600
}

# Laptop Kineton
resource "dns_a_record_set" "laptop-kineton" {
  zone      = "intranet.vflorio.com."
  name      = "laptop-kineton"
  addresses = ["192.168.1.9"]
  ttl       = 3600
}

resource "dns_a_record_set" "neon" {
  zone      = "intranet.vflorio.com."
  name      = "neon"
  addresses = ["192.168.1.9"]
  ttl       = 3600
}

# Gateway Iliad Box
resource "dns_a_record_set" "iliadbox" {
  zone      = "intranet.vflorio.com."
  name      = "iliadbox"
  addresses = ["192.168.1.254"]
  ttl       = 3600
}
