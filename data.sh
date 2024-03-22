#!/bin/bash

echo "/srv/nfs/ *(rw,no_root_squash,no_subtree_check,fsid=0)" >/etc/exports
exportfs -av

sudo mkdir /mnt/afs
if [ ! -d "/etc/smbcredentials" ]; then
sudo mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/fuseshare25.cred" ]; then
    sudo bash -c 'echo "username=fuseshare25" >> /etc/smbcredentials/fuseshare25.cred'
    sudo bash -c 'echo "password=E5y36dFvqYToy2hwXd2L6T9lzVjNalpYG/1YQKtgxWMFFIrimcttKbtDtCbtxNBOoBP2sk5qQxO++AStCj8//A==" >> /etc/smbcredentials/fuseshare25.cred'
fi
sudo chmod 600 /etc/smbcredentials/fuseshare25.cred

sudo bash -c 'echo "//fuseshare25.file.core.windows.net/afs /mnt/afs cifs nofail,credentials=/etc/smbcredentials/fuseshare25.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" >> /etc/fstab'
sudo mount -t cifs //fuseshare25.file.core.windows.net/afs /mnt/afs -o credentials=/etc/smbcredentials/fuseshare25.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30

cp -rvp /mnt/afs/* /srv/nfs/NW1/
