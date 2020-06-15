#!/bin/bash
sudo apt-get update		
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
mkfs -t ext4 /dev/xvdf
mount /dev/xvdf /var/www/html
echo /dev/xvdf /var/www/html ext4 defaults,nofail 0 2 >> /etc/fstab