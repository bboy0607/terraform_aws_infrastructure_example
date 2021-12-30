variable "i17-redis_count" {
  description = "the i17-redis server amount you want to build "
  type = number
  default = "4"
}

variable "i17-redis_instance_type" {
  description = "the i17-redis server instance type you want to build "
  default = "r5.xlarge"
}

variable "i17-redis_root_volume_size" {
  description = "the i17-redis server root size you want to build "
  type = number
  default = "50"
}

variable "i17-redis_ip_start" {
  description = "the i17-redis server ip you want to start "
  type = number
  default = "91"
}

resource "aws_security_group" "i17-redis" {
  name = "${var.app}-i17-redis-${var.domain}"
  description = "${var.app}-i17-redis-${var.domain}"
  vpc_id = "vpc-dcc736b9"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "i17-redis" {
  count = "${var.i17-redis_count}"
  ami             = "${var.ami}"
  instance_type   = "${var.i17-redis_instance_type}"
  subnet_id = "${var.subnet}"
  private_ip = "${cidrhost(data.aws_subnet.selected.cidr_block, var.i17-redis_ip_start + count.index)}"
  associate_public_ip_address = false
  vpc_security_group_ids = [ "sg-04b62587a0f813e0f", "${aws_security_group.i17-redis.id}" ]

  root_block_device {
    volume_size = "${var.i17-redis_root_volume_size}"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "20"
    delete_on_termination = "true"
  }

  tags = {
    "Name" = "${var.app}-i17-redis-${format("%03d", count.index + 1)}-${var.domain}"
    "App" = "${var.app}"
    "Domain" = "${var.domain}"
    "ServerType" = "GameDB"
  }
  volume_tags = {
    "Name" = "${var.app}-i17-redis-${format("%03d", count.index + 1)}-${var.domain}"
    "App" = "${var.app}"
    "Domain" = "${var.domain}"
    "ServerType" = "GameDB"
  }
  
  user_data = <<-EOT
        #!/bin/bash

        hostname="${var.app}-i17-redis-${format("%03d", count.index + 1)}-${var.domain}"
        master_ip='172.30.254.6'
        salt_code_name="${var.app}"
        salt_igsdomain="${var.domain}"
        salt_roles='redis'

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


        swap_disk=`lsblk | grep " 20G" | sort -r | head -1 | awk '{ print $1 }'`

        mkswap /dev/$swap_disk

        swapon /dev/$swap_disk

        swap_disk_uuid=`blkid | grep swap | awk '{ print $2 }'`

        echo "$swap_disk_uuid swap swap default 0 0" >> /etc/fstab

        reboot
  EOT
}

resource "aws_eip" "i17-redis_ip" {
  count = "${var.i17-redis_count}"
  instance = "${element(aws_instance.i17-redis.*.id,count.index)}"
  vpc = true
}
