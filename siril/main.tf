#Main terraform script for the Standalone machine "Siril"
#By: 0xreno
#License: GNU GPL v3
#NOTE: Make sure to run `export DIGITALOCEAN_TOKEN="ApiKeyGoesHere"` and add this to your .bashrc as well. This will be depreceated after Vault is implimented.

#Declares the variables from terraform.tfvars used in the script.
variable "droplet_region"    {}
variable "sshkey_pvt"        {}
variable "domain_main"       {}
variable "sshkey_name"       {}

provider "digitalocean"      {} 
 
#This sets the sshkey_name value to what is in the terraform.tfvars file. This shouhld be the exact name of the ssh key in Digital Ocean.
data "digitalocean_ssh_key" "ssh_key_pub_main" {
    name                = "${var.sshkey_name}"
}

resource "digitalocean_droplet" "siril" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "sirl" #The name of the machine in digital ocean.
    region              = "${var.droplet_region}" #Varilable for the region that the machine will be spun up in.
    size                = "4gb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"] #This is the ssh key that terraform will use to provision the machines.

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "apt install -y masscan nmap sqlmap beef certbot build-essential libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev libyaml-dev curl zlib1g-dev gawk bison libffi-dev libgdbm-dev libncurses5-dev libtool sqlite3 libgmp-dev gnupg2 dirmngr",
            "add-apt-repository ppa:webupd8team/java -y", #The next 3 lines installs java 8 on the machine.
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
        ]

#This is the connection details terraform uses to connect to the box.    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
}

resource "digitalocean_record" "siril" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "siril"
    value               = "${digitalocean_droplet.siril.ipv4_address}"
}