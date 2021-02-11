## Install stress
sudo amazon-linux-extras install epel -y
sudo yum install stress-ng -y
stress-ng -c 20 -t 60m -v