# Cloudflare Credentials
# ---
# Credential Variables needed for Cloudflare

# Cloudflare Config
 
variable "cloudflare_api_token" {
    description = "The API Token for your Cloudflare account"
    type = string
}

variable "cloudflare_zone_id" {
    description = "The Zone ID for your Cloudflare account"
    type = string
}

variable "public_ipv6" {
    description = "The Public IPv6 Address to be used for the DNS Record"
    type = string
}