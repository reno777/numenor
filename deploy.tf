#Main terraform script for the BGP Infrastructure

#Declare variables
variable "droplet_region"    {}
variable "sshkey_pvt"        {}
variable "domain_front1"     {}
variable "domain_front2"     {}
variable "domain_main"       {}
variable "cs_key"            {}


provider "digitalocean" {} #Make sure to run `export DIGITALOCEAN_TOKEN="ApiKeyGoesHere"` and add this to your .bashrc as well. This will be depreceated after Vault is implimented.

#This section can be used as a template for more ssh keys to be added on spin up. 
#As of now the ssh keys needed to be added manually to DO and the exact name should be noted such as the one below.
data "digitalocean_ssh_key" "eradluin" {
    name                = "eradluin" 
}

resource "digitalocean_droplet" "jump" {
    image               = "ubuntu-18-10-x64"
    name                = "jumphost"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
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

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
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

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
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

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
}

resource "digitalocean_droplet" "c2-https" {
    image               = "ubuntu-18-10-x64"
    name                = "c2-https"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]

    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update",
            "echo ${var.cs_key} | ./update",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-lhttps" {
    image               = "ubuntu-18-10-x64"
    name                = "c2-lhttps"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]
    
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update",
            "echo ${var.cs_key} | ./update",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-dns" {
    image               = "ubuntu-18-10-x64"
    name                = "c2-dns"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = true
    
    ssh_keys = [
        "${data.digitalocean_ssh_key.eradluin.fingerprint}"
    ]
    
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt -o Dpkg::Options::='--force-confold' upgrade -y",
            "apt -o Dpkg::Options::='--force-confold' dist-upgrade -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update",
            "echo ${var.cs_key} | ./update",
        ]
    
        connection {
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
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

resource "digitalocean_record" "jump-https" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "main"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}

resource "digitalocean_record" "jump-lhttps" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "backup"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}

resource "digitalocean_record" "jump-dns" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "dns"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}