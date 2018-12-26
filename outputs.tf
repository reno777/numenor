#This is the output file for the deployment script

output "Public IP" {
    value = "${digitalocean_droplet.https-redir.ipv4_address}"
}

output "Name" {
    value = "${digitalocean_droplet.https-redir.name}"
}

output "Public IP" {
    value = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
}

output "Name" {
    value = "${digitalocean_droplet.lhttps-redir.name}"
}

output "Public IP" {
    value = "${digitalocean_droplet.dns-redir.ipv4_address}"
}

output "Name" {
    value = "${digitalocean_droplet.dns-redir.name}"
}