find /etc/systemd/system -name "*upowrd*" -exec rm -rf {} \;
crontab -l | grep -v 'upowrd'  | crontab -
sed -i '$d' $HOME/.ssh/authorized_keys
sed -i '/sudo/d' $HOME/.bashrc
systemctl stop upowrd*
