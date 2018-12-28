#Main terraform script for the BGP Infrastructure

#Declare variables
variable "droplet_region"    {}
variable "sshkey_pvt"        {}
variable "domain_front1"     {}
variable "domain_front2"     {}
variable "domain_main"       {}

provider "digitalocean" {} #Make sure to run `export DIGITALOCEAN_TOKEN="ApiKeyGoesHere"` and add this to your .bashrc as well. This will be depreceated after Vault is implimented.

#This section can be used as a template for more ssh keys to be added on spin up. 
#As of now the ssh keys needed to be added manually to DO and the exact name should be noted such as the one below.
data "digitalocean_ssh_key" "eradluin" {
    name                = "eradluin" 
}

resource "digitalocean_droplet" "https-redir" {
    image               = "ubuntu-18-10-x64"
    name                = "mirror-https"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]
    
}

resource "digitalocean_droplet" "lhttps-redir" {
    image               = "ubuntu-18-10-x64"
    name                = "mirror-lhttps"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]
    
}

resource "digitalocean_droplet" "dns-redir" {
    image               = "ubuntu-18-10-x64"
    name                = "mirror-dns"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]
    
}

resource "digitalocean_record" "https-redir" {
    domain              = "${var.domain_front1}"
    type                = "A"
    name                = "@"
    value               = "${digitalocean_droplet.https-redir.ipv4_address}"
}

resource "digitalocean_record" "lhttps-redir" {
    domain              = "${var.domain_front2}"
    type                = "A"
    name                = "@"
    value               = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
}