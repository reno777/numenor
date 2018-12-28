#This is the output file for the deployment script

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

output "C2-HTTPS IP" {
    value = "${digitalocean_droplet.c2-https.ipv4_address}"
}