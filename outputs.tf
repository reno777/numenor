#This is the output file for the deployment script

output "C2-HTTPS IP" {
    value = "${digitalocean_droplet.c2-https.ipv4_address}"
}

output "C2-LHTTPS IP" {
    value = "${digitalocean_droplet.c2-lhttps.ipv4_address}"
}

output "C2-DNS IP" {
    value = "${digitalocean_droplet.c2-dns.ipv4_address}"
}

output "JUMPHOST IP" {
    value = "${digitalocean_droplet.jump.ipv4_address}"
}

output "JUMP-HTTPS FQDN" {
    value = "${digitalocean_record.jump-https.fqdn}"
}

output "JUMP-LHTTPS FQDN" {
    value = "${digitalocean_record.jump-lhttps.fqdn}"
}

output "JUMP-DNS FQDN" {
    value = "${digitalocean_record.jump-dns.fqdn}"
}

output "MIRROR-HTTPS IP" {
    value = "${digitalocean_droplet.https-redir.ipv4_address}"
}

output "MIRROR-HTTPS FQDN" {
    value = "${digitalocean_record.https-redir.fqdn}"
}

output "MIRROR-LHTTPS IP" {
    value = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
}

output "MIRROR-LHTTPS FQDN" {
    value = "${digitalocean_record.lhttps-redir.fqdn}"
}

output "MIRROR-DNS IP" {
    value = "${digitalocean_droplet.dns-redir.ipv4_address}"
}