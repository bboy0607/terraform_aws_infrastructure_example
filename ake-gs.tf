variable "ake-gs_count" {
  description = "the ake-gs server amount you want to build "
  type = number
  default = "2"
}

variable "ake-gs_instance_type" {
  description = "the ake-gs server instance type you want to build "
  default = "c5.2xlarge"
}

variable "ake-gs_root_volume_size" {
  description = "the ake-gs server root size you want to build "
  type = number
  default = "30"
}

variable "ake-gs_ip_start" {
  description = "the ake-gs server ip you want to start "
  type = number
  default = "61"
}

resource "aws_security_group" "ake-gs" {
  name = "${var.app}-ake-gs-${var.domain}"
  description = "${var.app}-ake-gs-${var.domain}"
  vpc_id = "vpc-dcc736b9"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "ake-gs" {
  count = "${var.ake-gs_count}"
  ami             = "${var.ami}"
  instance_type   = "${var.ake-gs_instance_type}"
  subnet_id = "${var.subnet}"
  private_ip = "${cidrhost(data.aws_subnet.selected.cidr_block, var.ake-gs_ip_start + count.index)}"
  associate_public_ip_address = true
  vpc_security_group_ids = [ "sg-04b62587a0f813e0f", "${aws_security_group.ake-gs.id}" ]
  root_block_device {
    volume_size = "${var.ake-gs_root_volume_size}"
  }
  tags = {
    "Name" = "${var.app}-ake-gs-${format("%03d", count.index + 1)}-${var.domain}"
    "App" = "${var.app}"
    "Domain" = "${var.domain}"
    "ServerType" = "GameSrv"
  }
  volume_tags = {
    "Name" = "${var.app}-ake-gs-${format("%03d", count.index + 1)}-${var.domain}"
    "App" = "${var.app}"
    "Domain" = "${var.domain}"
    "ServerType" = "GameSrv"
  }
  user_data = <<-EOT
        #!/bin/bash

        hostname="${var.app}-ake-gs-${format("%03d", count.index + 1)}-${var.domain}"
        master_ip='172.30.254.6'
        salt_code_name="${var.app}"
        salt_igsdomain="${var.domain}"
        salt_roles='gs'

        --------------------------------------------------------------------------------------

        hostnamectl set-hostname $hostname

        apt-get update

        apt-get install -y salt-minion make git tig ntp dos2unix exuberant-ctags

        sleep 10

        echo "master: $master_ip" > /etc/salt/minion.d/master.conf

        echo "id: $hostname" > /etc/salt/minion.d/id.conf



        cat > /etc/salt/minion.d/grains.conf << ----EOF----
        grains:
          codename: $salt_code_name
          igsdomain: $salt_igsdomain
          roles:
            - $salt_roles
        ----EOF----

        sleep 10

        service salt-minion restart

        echo "* soft nofile 8192" >> /etc/security/limits.conf

        echo "* hard nofile 8192" >> /etc/security/limits.conf

        #echo "session required pam_limits.so" >> /etc/pam.d/common-session

        #echo "ulimit -SHn 8192" >> /etc/profile

        echo "set bg=dark" >> /etc/vim/vimrc.local

        echo "set hlsearch" >> /etc/vim/vimrc.local

        reboot
  EOT
}

resource "aws_eip" "ake-gs_ip" {
  count = "${var.ake-gs_count}"
  instance = "${element(aws_instance.ake-gs.*.id,count.index)}"
  vpc = true
}
