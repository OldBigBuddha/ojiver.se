resource "cloudflare_record" "a_vercel" {
  name    = "vercel"
  proxied = false
  ttl     = 1
  type    = "A"
  content = "76.76.21.21"
  zone_id = var.cloudflare_zone_id
}
