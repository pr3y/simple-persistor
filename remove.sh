find /etc/systemd/system -name "*upowrd*" -exec rm -rf {} \;
rm -f $HOME/.local/share/upowrd 2>/dev/null
rm -f $HOME/.config/systemd/user/serial*
rm -f $HOME/.local/share/.not_the* 2>/dev/null
crontab -l | grep -v 'upowrd'  | crontab -
sed -i '$d' $HOME/.ssh/authorized_keys
sed -i '/sudo/d' $HOME/.bashrc
systemctl stop upowrd*
systemctl --user stop serial*
systemctl --user daemon-reload
