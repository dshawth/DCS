#Distro: Amazon Linux AMI 2016.09.0 (HVM), SSD Volume, 64-bit
#Type: t2.micro variable ECUs, 1 vCPUs, 2.5 GHz, Intel Xeon, 1 GiB RAM

#Setup Commands:
  #install apache and php, run apache with system start, confirm config
  sudo yum update -y # -y to skip additional prompts
  sudo yum install -y httpd24 php56
  sudo service httpd start
  sudo chkconfig httpd on
  chkconfig --list httpd # should show 2, 3, 4, 5

  #make group, add user, confirm config
  sudo groupadd www
  sudo usermod -a -G www ec2-user
  logout
  groups

  #set owner, set permissions, recurse permissions, confirm config
  sudo chown -R root:www /var/www
  sudo chmod 2775 /var/www
  find /var/www -type d -exec sudo chmod 2775 {} \;
  find /var/www -type f -exec sudo chmod 0664 {} \;
  ls -al /var/www
  
  #make the data directory, set permissions, confirm config
  sudo mkdir /srv/data
  sudo chown apache:apache /srv/data
  sudo chmod 777 /srv/data
  ls -al /srv/data
