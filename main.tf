#Main terraform script for the Red Team Infrastructure
#Author: 0xreno
#License: GNU GPL v3
#NOTE: Make sure to run `export DIGITALOCEAN_TOKEN="ApiKeyGoesHere"` and add this to your .bashrc as well. This will be depreceated after Vault is implimented.

#Declares the variables from terraform.tfvars used in the script.
variable "droplet_region"    {}
variable "sshkey_pvt"        {}
variable "domain_front1"     {}
variable "domain_front2"     {}
variable "domain_dns"        {}
variable "domain_main"       {}
variable "cs_key"            {}
variable "sshkey_name"       {}
variable "op_name"           {}
variable "ops_num"           {}

terraform {
    required_providers {
        digitalocean = {
            source = "digitalocean/digitalocean"
        }
    }
}
provider "digitalocean"      {}

#This sets the sshkey_name value to what is in the terraform.tfvars file. This shouhld be the exact name of the ssh key in Digital Ocean.
data "digitalocean_ssh_key" "ssh_key_pub_main" {
    name                = var.sshkey_name
}

#This gets the current public IP address of the machine running terraform, which will be used in the iptables rules for each machine.
data "http" "local_ip" {
    url                 = "http://ipv4.icanhazip.com"
}

#This generates a random character password to be used for Cobalt Strike. This password is also used in generating the SSL certs.
resource "random_string" "cs_password" {
    length              = 24
    special             = false
}
#This resource is used to spin up the jumphost machine.
resource "digitalocean_droplet" "jump" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-jumphost" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "512mb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the jumphost machine, written in bash.
resource "null_resource" "jump-provision" {
    depends_on          = [digitalocean_droplet.jump]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.jump.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

}

resource "digitalocean_droplet" "https-redir" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-mirror-https" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "512mb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the https-redir machine, written in bash.
resource "null_resource" "http-redir-provision" {
    depends_on          = [digitalocean_droplet.https-redir]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
	        "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.https-redir.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

}

resource "digitalocean_droplet" "lhttps-redir" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-mirror-lhttps" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "512mb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the lhttps-redir machine, written in bash.
resource "null_resource" "lhttps-redir-provision" {
    depends_on          = [digitalocean_droplet.lhttps-redir]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 1 > /proc/sys/net/ipv4/ip_forward", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.lhttps-redir.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

}

resource "digitalocean_droplet" "dns-redir" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-mirror-dns" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "512mb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the dns-redir machine, written in bash.
resource "null_resource" "dns-redir-provision" {
    depends_on          = [digitalocean_droplet.dns-redir]
    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf", #This line adds a public DNS server in order for the beacon to talk to the server
            "echo 1 > /proc/sys/net/ipv4/ip_forward", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.dns-redir.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-https" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-c2-https" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "2gb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the c2-https machine, written in bash. The file provisioner transfers the files needed to setup Cobalt Strike. These files need to be place on the machine prior to the script running.
resource "null_resource" "c2-https-provision" {
    depends_on          = [digitalocean_droplet.c2-https]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-https.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "apt install python-pip -y", #The next 2 lines install pip and the python slackweb library.
            "pip install slackweb",
            "apt install openjdk-11-jdk -y", #The next 2 lines installs java 8 on the machine.
            "update-java-alternatives -s java-1.11.0-openjdk-amd64",
            "snap install --classic certbot", #The next 21 lines setups Cobalt Strike and the SSL certificates needed for c2-https and c2-lhttps.
            "certbot certonly --standalone -d ${digitalocean_record.https-redir.fqdn} -n --register-unsafely-without-email --agree-tos",
            "cd /cobaltstrike",
            "chmod -R 700 update teamserver slackhook${var.ops_num}.py agscript",
            "echo ${var.cs_key} | ./update",
            "mkdir httpsProfiles/ && cd httpsProfiles/",
            "wget https://raw.githubusercontent.com/rsmudge/Malleable-C2-Profiles/master/normal/amazon.profile",
            "echo ''  >> amazon.profile",
            "echo 'https-certificate {' >> amazon.profile",
            "cd /etc/letsencrypt/live/${digitalocean_record.https-redir.fqdn}",
            "openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out ${digitalocean_record.https-redir.fqdn}.p12 -name ${digitalocean_record.https-redir.fqdn} -passout pass:${random_string.cs_password.result}",
            "keytool -importkeystore -deststorepass ${random_string.cs_password.result} -destkeypass ${random_string.cs_password.result} -destkeystore ${digitalocean_record.https-redir.fqdn}.store -srckeystore ${digitalocean_record.https-redir.fqdn}.p12 -srcstoretype PKCS12 -srcstorepass ${random_string.cs_password.result} -alias ${digitalocean_record.https-redir.fqdn}",
            "cd ~",
            "cp /etc/letsencrypt/live/${digitalocean_record.https-redir.fqdn}/${digitalocean_record.https-redir.fqdn}.store /cobaltstrike/httpsProfiles/${digitalocean_record.https-redir.fqdn}.store",
            "cd /cobaltstrike",
            "echo '    set keystore \"${digitalocean_record.https-redir.fqdn}.store\";' >> httpsProfiles/amazon.profile",
            "echo '    set password \"${random_string.cs_password.result}\";' >> httpsProfiles/amazon.profile",
            "echo '}' >> httpsProfiles/amazon.profile",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-https.ipv4_address} ${random_string.cs_password.result} httpsProfiles/amazon.profile'",
            "sleep 10",
            "tmux new-session -d -s bot 'cd /cobaltstrike; ./agscript 127.0.0.1 50050 R2-C2 ${random_string.cs_password.result} beaconnotification${var.ops_num}.cna'",
            "iptables -F", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-https.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-lhttps" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-c2-lhttps" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "2gb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the c2-lhttps machine, written in bash. The file provisioner transfers the files needed to setup Cobalt Strike. These files need to be place on the machine prior to the script running.
resource "null_resource" "c2-lhttps-provision" {
    depends_on          = [digitalocean_droplet.c2-lhttps]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-lhttps.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "apt install python-pip -y", #The next 2 lines install pip and the python slackweb library.
            "pip install slackweb",
            "apt install openjdk-11-jdk -y", #The next 2 lines installs java 8 on the machine.
            "update-java-alternatives -s java-1.11.0-openjdk-amd64",
            "snap install --classic certbot", #The next 21 lines setups Cobalt Strike and the SSL certificates needed for c2-https and c2-lhttps.
            "certbot certonly --standalone -d ${digitalocean_record.lhttps-redir.fqdn} -n --register-unsafely-without-email --agree-tos",
            "cd /cobaltstrike",
            "chmod -R 700 update teamserver slackhook${var.ops_num}.py agscript",
            "echo ${var.cs_key} | ./update",
            "mkdir httpsProfiles/ && cd httpsProfiles/",
            "wget https://raw.githubusercontent.com/rsmudge/Malleable-C2-Profiles/master/normal/amazon.profile",
            "echo ''  >> amazon.profile",
            "echo 'https-certificate {' >> amazon.profile",
            "cd /etc/letsencrypt/live/${digitalocean_record.lhttps-redir.fqdn}",
            "openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out ${digitalocean_record.lhttps-redir.fqdn}.p12 -name ${digitalocean_record.lhttps-redir.fqdn} -passout pass:${random_string.cs_password.result}",
            "keytool -importkeystore -deststorepass ${random_string.cs_password.result} -destkeypass ${random_string.cs_password.result} -destkeystore ${digitalocean_record.lhttps-redir.fqdn}.store -srckeystore ${digitalocean_record.lhttps-redir.fqdn}.p12 -srcstoretype PKCS12 -srcstorepass ${random_string.cs_password.result} -alias ${digitalocean_record.lhttps-redir.fqdn}",
            "cd ~",
            "cp /etc/letsencrypt/live/${digitalocean_record.lhttps-redir.fqdn}/${digitalocean_record.lhttps-redir.fqdn}.store /cobaltstrike/httpsProfiles/${digitalocean_record.lhttps-redir.fqdn}.store",
            "cd /cobaltstrike",
            "echo '    set keystore \"${digitalocean_record.lhttps-redir.fqdn}.store\";' >> httpsProfiles/amazon.profile",
            "echo '    set password \"${random_string.cs_password.result}\";' >> httpsProfiles/amazon.profile",
            "echo '}' >> httpsProfiles/amazon.profile",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-lhttps.ipv4_address} ${random_string.cs_password.result} httpsProfiles/amazon.profile'",
            "sleep 10",
            "tmux new-session -d -s bot 'cd /cobaltstrike; ./agscript 127.0.0.1 50050 R2-C2 ${random_string.cs_password.result} beaconnotification${var.ops_num}.cna'",
            "iptables -F", #The rest of the lines pushes iptables rules to the machine.
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
#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-lhttps.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }
}

resource "digitalocean_droplet" "c2-dns" {
    image               = "ubuntu-18-04-x64" #The OS the machine will run.
    name                = "${var.op_name}-c2-dns" #The name of the machine in digital ocean.
    region              = var.droplet_region #Varilable for the region that the machine will be spun up in.
    size                = "2gb" #The RAM size being used to spin up the machine. This is what affects cost in Digital Ocean.
    ipv6                = false #Boolean to set wether or not the machine has ipv6 networking.
    private_networking  = false #Boolean to set wether or not the machine is on a private network.
    monitoring          = false #Boolean to set up Digital Ocean Monitoring on the machine. NOTE: This needs to be false in order for the machines to update correctly. If set to true apt becomes locked.
    ssh_keys            = [data.digitalocean_ssh_key.ssh_key_pub_main.fingerprint] #This is the ssh key that terraform will use to provision the machines.
}

#This null resource provisions or is the setup for the c2-dns machine, written in bash. The file provisioner transfers the files needed to setup Cobalt Strike. These files need to be place on the machine prior to the script running.
resource "null_resource" "c2-dns-provision" {
    depends_on          = [digitalocean_droplet.c2-dns]
    provisioner "file" {
        source          = "/cobaltstrike"
        destination     = "/."

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-dns.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "export DEBIAN_FRONTEND=noninteractive", #The next 4 lines updates the machine after creation.
            "apt update",
            "apt upgrade -y",
            "apt auto-remove -y",
            "apt install python-pip -y", #The next 2 lines install pip and the python slackweb library.
            "pip install slackweb",
            "apt install openjdk-11-jdk -y", #The next 2 lines installs java 8 on the machine.
            "update-java-alternatives -s java-1.11.0-openjdk-amd64",
            "cd /cobaltstrike", #The next 4 lines setups Cobalt Strike.
            "chmod -R 700 update teamserver slackhook${var.ops_num}.py agscript",
            "echo ${var.cs_key} | ./update",
            "tmux new-session -d -s cobalt_strike 'cd /cobaltstrike; ./teamserver ${digitalocean_droplet.c2-dns.ipv4_address} ${random_string.cs_password.result}'",
            "sleep 10",
            "tmux new-session -d -s bot 'cd /cobaltstrike; ./agscript 127.0.0.1 50050 R2-C2 ${random_string.cs_password.result} beaconnotification${var.ops_num}.cna'",
            "systemctl disable systemd-resolved", #This line and the next disables port 53 from being used by default on 18.04
            "systemctl stop systemd-resolved",
            "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf", #This line adds a public DNS server in order for the beacon to talk to the server
            "iptables -F", #The rest of the lines pushes iptables rules to the machine.
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

#This is the connection details terraform uses to connect to the box.
        connection {
            host        = digitalocean_droplet.c2-dns.ipv4_address
            user        = "root"
            type        = "ssh"
            private_key = chomp(file(var.sshkey_pvt))
            timeout     = "2m"
        }
    }
}

#The following 5 resources are for the setup for the domains needed for the environment
resource "digitalocean_record" "https-redir" {
    domain              = var.domain_front1
    type                = "A"
    name                = "www"
    value               = digitalocean_droplet.https-redir.ipv4_address
}

resource "digitalocean_record" "lhttps-redir" {
    domain              = var.domain_front2
    type                = "A"
    name                = "www"
    value               = digitalocean_droplet.lhttps-redir.ipv4_address
}

resource "digitalocean_record" "dns-redir" {
    domain              = var.domain_dns
    type                = "A"
    name                = "ns1"
    value               = digitalocean_droplet.dns-redir.ipv4_address
}

resource "digitalocean_record" "dns-ns" {
    domain              = var.domain_dns
    type                = "NS"
    name                = "dns"
    value               = "${digitalocean_record.dns-redir.fqdn}."
}

resource "digitalocean_record" "jump-https" {
    domain              = var.domain_main
    type                = "A"
    name                = "ops${var.ops_num}"
    value               = digitalocean_droplet.jump.ipv4_address
}

resource "digitalocean_record" "jump-lhttps" {
    domain              = var.domain_main
    type                = "A"
    name                = "backup${var.ops_num}"
    value               = digitalocean_droplet.jump.ipv4_address
}

resource "digitalocean_record" "jump-dns" {
    domain              = var.domain_main
    type                = "A"
    name                = "dns${var.ops_num}"
    value               = digitalocean_droplet.jump.ipv4_address
}
