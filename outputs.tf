#This file contains the code necessary for terraform to output the IPs and FQDNs of the machines spun up after the script runs.

#This outputs the IP address for the c2-https instance.
output "C2-HTTPS IP" {
    value = "${digitalocean_droplet.c2-https.ipv4_address}"
}

#This outputs the IP address for the c2-lhttps instance.
output "C2-LHTTPS IP" {
    value = "${digitalocean_droplet.c2-lhttps.ipv4_address}"
}

#This outputs the IP addres for the c2-dns instance.
output "C2-DNS IP" {
    value = "${digitalocean_droplet.c2-dns.ipv4_address}"
}

#This outputs the IP address for the jumphost instance.
output "JUMPHOST IP" {
    value = "${digitalocean_droplet.jump.ipv4_address}"
}

#This outputs one of the FQDN for the jumphost instance.
output "JUMP-HTTPS FQDN" {
    value = "${digitalocean_record.jump-https.fqdn}"
}

#This outputs one of the FQDN for the jumphost instance.
output "JUMP-LHTTPS FQDN" {
    value = "${digitalocean_record.jump-lhttps.fqdn}"
}

#This outputs one of the FQDN for the jumphost instance.
output "JUMP-DNS FQDN" {
    value = "${digitalocean_record.jump-dns.fqdn}"
}

#This outputs the IP address for the https redirector instance.
output "MIRROR-HTTPS IP" {
    value = "${digitalocean_droplet.https-redir.ipv4_address}"
}

#This outputs the FQDN for the https redirector instance.
output "MIRROR-HTTPS FQDN" {
    value = "${digitalocean_record.https-redir.fqdn}"
}

#This outputs the IP address for the lhttps redirector instance.
output "MIRROR-LHTTPS IP" {
    value = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
}

#This outputs the FQDN for the lhttps redirector instance.
output "MIRROR-LHTTPS FQDN" {
    value = "${digitalocean_record.lhttps-redir.fqdn}"
}

#This outputs the IP address for the dns redirector instance.
output "MIRROR-DNS IP" {
    value = "${digitalocean_droplet.dns-redir.ipv4_address}"
}

#This outputs the FQDN for the dns redirector instance.
output "MIRROR-DNS FQDN" {
    value = "${digitalocean_record.dns-redir.fqdn}"
}

#This outputs the FQDN for the name server portion of the dns redirector instance.
output "MIRROR-DNS NS" {
    value = "${digitalocean_record.dns-ns.fqdn}"
}

#This outputs the password used to start and login to the Cobalt Strike instances located on c2-https, c2-lhttp, and c2-dns.
output "CS PASSWORD" {
    value = "${random_string.cs_password.result}"
}
