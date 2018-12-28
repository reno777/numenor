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
