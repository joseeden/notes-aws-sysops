sudo yum -y install amazon-efs-utils
sudo mkdir /mnt/efs
sudo mount -t efs fs-482cd170:/ /mnt/efs