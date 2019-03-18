#Main terraform script for the Red Team Infrastructure
#By: 0xreno
#License: GNU GPL v3

#Declare variables
variable "droplet_region"    {}
variable "sshkey_pvt"        {}
variable "domain_front1"     {}
variable "domain_front2"     {}
variable "domain_main"       {}
variable "cs_key"            {}
variable "sshkey_name"       {}


provider "digitalocean"      {} #Make sure to run `export DIGITALOCEAN_TOKEN="ApiKeyGoesHere"` and add this to your .bashrc as well. This will be depreceated after Vault is implimented.

#This section can be used as a template for more ssh keys to be added on spin up. 
#As of now the ssh keys needed to be added manually to DO and the exact name should be noted such as the one below.

data "digitalocean_ssh_key" "ssh_key_pub_main" {
    name                = "${var.sshkey_name}" 
}

data "http" "local_ip" {
    url                 = "http://ipv4.icanhazip.com"
}

resource "random_string" "cs_password" {
    length              = 24
    special             = false
}

resource "digitalocean_droplet" "jump" {
    image               = "ubuntu-18-04-x64"
    name                = "jumphost"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}

resource "null_resource" "jump-provision" {
    depends_on          = ["digitalocean_droplet.jump"]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -t nat -A PREROUTING -p tcp --dport 56651 -j DNAT --to-destination ${digitalocean_droplet.c2-https.ipv4_address}:50050",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-https.ipv4_address} --dport 50050 -j SNAT --to-source ${digitalocean_droplet.jump.ipv4_address}",
            "iptables -t nat -A PREROUTING -p tcp --dport 56652 -j DNAT --to-destination ${digitalocean_droplet.c2-lhttps.ipv4_address}:50050",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-lhttps.ipv4_address} --dport 50050 -j SNAT --to-source ${digitalocean_droplet.jump.ipv4_address}",
            "iptables -t nat -A PREROUTING -p tcp --dport 56653 -j DNAT --to-destination ${digitalocean_droplet.c2-dns.ipv4_address}:50050",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-dns.ipv4_address} --dport 50050 -j SNAT --to-source ${digitalocean_droplet.jump.ipv4_address}",
        ]
    
        connection {
            host        = "${digitalocean_droplet.jump.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
}

resource "digitalocean_droplet" "https-redir" {
    image               = "ubuntu-18-04-x64"
    name                = "mirror-https"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}

resource "null_resource" "http-redir-provision" {
    depends_on          = ["digitalocean_droplet.https-redir"]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt upgrade -y",
	    "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination ${digitalocean_droplet.c2-https.ipv4_address}:443",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-https.ipv4_address} --dport 443 -j SNAT --to-source ${digitalocean_droplet.https-redir.ipv4_address}",
            "iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${digitalocean_droplet.c2-https.ipv4_address}:80",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-https.ipv4_address} --dport 80 -j SNAT --to-source ${digitalocean_droplet.https-redir.ipv4_address}",
            "iptables -t nat -A POSTROUTING -j MASQUERADE",
            "sysctl net.ipv4.ip_forward=1",
            "iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT",
            "iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT",
            "iptables -A INPUT -p tcp -s ${chomp(data.http.local_ip.body)} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s ${digitalocean_droplet.jump.ipv4_address} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 22 -j DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.https-redir.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
}

resource "digitalocean_droplet" "lhttps-redir" {
    image               = "ubuntu-18-04-x64"
    name                = "mirror-lhttps"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}

resource "null_resource" "lhttps-redir-provision" {
    depends_on          = ["digitalocean_droplet.lhttps-redir"]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination ${digitalocean_droplet.c2-lhttps.ipv4_address}:443",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-lhttps.ipv4_address} --dport 443 -j SNAT --to-source ${digitalocean_droplet.lhttps-redir.ipv4_address}",
            "iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${digitalocean_droplet.c2-lhttps.ipv4_address}:80",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-lhttps.ipv4_address} --dport 80 -j SNAT --to-source ${digitalocean_droplet.lhttps-redir.ipv4_address}",
            "iptables -t nat -A POSTROUTING -j MASQUERADE",
            "sysctl net.ipv4.ip_forward=1",
            "iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT",
            "iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT",
            "iptables -A INPUT -p tcp -s ${chomp(data.http.local_ip.body)} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s ${digitalocean_droplet.jump.ipv4_address} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 22 -j DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
}

resource "digitalocean_droplet" "dns-redir" {
    image               = "ubuntu-18-04-x64"
    name                = "mirror-dns"
    region              = "${var.droplet_region}"
    size                = "512mb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}

resource "null_resource" "dns-redir-provision" {
    depends_on          = ["digitalocean_droplet.dns-redir"]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination ${digitalocean_droplet.c2-dns.ipv4_address}:53",
            "iptables -t nat -A POSTROUTING -p tcp -d ${digitalocean_droplet.c2-dns.ipv4_address} --dport 53 -j SNAT --to-source ${digitalocean_droplet.dns-redir.ipv4_address}",
            "iptables -I INPUT -p udp -m udp --dport 53 -j ACCEPT",
            "iptables -A INPUT -p tcp -m tcp --dport 53 -j ACCEPT",
            "iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination ${digitalocean_droplet.c2-dns.ipv4_address}:53",
            "iptables -t nat -A POSTROUTING -p udp -d ${digitalocean_droplet.c2-dns.ipv4_address} --dport 53 -j SNAT --to-source ${digitalocean_droplet.dns-redir.ipv4_address}",
            "iptables -t nat -A POSTROUTING -j MASQUERADE",
            "sysctl net.ipv4.ip_forward=1",
            "iptables -A INPUT -p tcp -s ${chomp(data.http.local_ip.body)} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s ${digitalocean_droplet.jump.ipv4_address} --dport 22 -j ACCEPT",
            "iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 22 -j DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.dns-redir.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
    
}

resource "digitalocean_droplet" "c2-https" {
    image               = "ubuntu-18-04-x64"
    name                = "c2-https"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}

resource "null_resource" "c2-https-provision" {
    depends_on          = ["digitalocean_droplet.c2-https"]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            host        = "${digitalocean_droplet.c2-https.ipv4_address}"
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
            "apt upgrade -y",
            "apt auto-remove -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update && chmod 700 teamserver",
            "echo ${var.cs_key} | ./update",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-https.ipv4_address} ${random_string.cs_password.result}'",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -P FORWARD DROP",
            "iptables -A INPUT -m state --state INVALID -j DROP",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -A INPUT -i lo -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.https-redir.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.jump.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${chomp(data.http.local_ip.body)} -j ACCEPT",
            "iptables -P INPUT DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.c2-https.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-lhttps" {
    image               = "ubuntu-18-04-x64"
    name                = "c2-lhttps"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}
    
resource "null_resource" "c2-lhttps-provision" {
    depends_on          = ["digitalocean_droplet.c2-lhttps"]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            host        = "${digitalocean_droplet.c2-lhttps.ipv4_address}"
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
            "apt upgrade -y",
            "apt auto-remove -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update && chmod 700 teamserver",
            "echo ${var.cs_key} | ./update",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-lhttps.ipv4_address} ${random_string.cs_password.result}'",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -P FORWARD DROP",
            "iptables -A INPUT -m state --state INVALID -j DROP",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -A INPUT -i lo -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.lhttps-redir.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.jump.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${chomp(data.http.local_ip.body)} -j ACCEPT",
            "iptables -P INPUT DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.c2-lhttps.ipv4_address}"
            user        = "root"
            type        = "ssh"
            private_key = "${chomp(file(var.sshkey_pvt))}"
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-dns" {
    image               = "ubuntu-18-04-x64"
    name                = "c2-dns"
    region              = "${var.droplet_region}"
    size                = "2gb"
    ipv6                = false
    private_networking  = false
    monitoring          = false
    
    ssh_keys            = ["${data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint}"]
}
    
resource "null_resource" "c2-dns-provision" {
    depends_on          = ["digitalocean_droplet.c2-dns"]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."
    
        connection {
            host        = "${digitalocean_droplet.c2-dns.ipv4_address}"
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
            "apt upgrade -y",
            "apt auto-remove -y",
            "add-apt-repository ppa:webupd8team/java -y",
            "echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections",
            "apt install oracle-java8-installer -y",
            "cd /cobaltstrike",
            "chmod 700 update && chmod 700 teamserver",
            "echo ${var.cs_key} | ./update",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-dns.ipv4_address} ${random_string.cs_password.result}'",
            "iptables -F",
            "iptables -t nat -F",
            "iptables -X",
            "iptables -P FORWARD DROP",
            "iptables -A INPUT -m state --state INVALID -j DROP",
            "iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT",
            "iptables -A INPUT -i lo -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.dns-redir.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${digitalocean_droplet.jump.ipv4_address} -j ACCEPT",
            "iptables -A INPUT -s ${chomp(data.http.local_ip.body)} -j ACCEPT",
            "iptables -P INPUT DROP",
        ]
    
        connection {
            host        = "${digitalocean_droplet.c2-dns.ipv4_address}"
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
    name                = "www"
    value               = "${digitalocean_droplet.https-redir.ipv4_address}"
}

resource "digitalocean_record" "lhttps-redir" {
    domain              = "${var.domain_front2}"
    type                = "A"
    name                = "www"
    value               = "${digitalocean_droplet.lhttps-redir.ipv4_address}"
}

resource "digitalocean_record" "jump-https" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "opsX"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}

resource "digitalocean_record" "jump-lhttps" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "backupX"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}

resource "digitalocean_record" "jump-dns" {
    domain              = "${var.domain_main}"
    type                = "A"
    name                = "dnsX"
    value               = "${digitalocean_droplet.jump.ipv4_address}"
}
