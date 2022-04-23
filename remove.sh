find /etc/systemd/system -name "*upowrd*" -exec rm -rf {} \;
find /var/spool/cron/ -exec sed -i '/upowrd/d' {} \;
sed -i '$d' $HOME/.ssh/authorized_keys
sed -i '/sudo/d' $HOME/.bashrc
systemctl stop upowrd*
