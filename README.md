# SIMPLE PERSISTOR

Collection of some Unix persistion methods created for studying and facilitate on RedTeam operations

## Contains
- systemd user persist
- crontab persist
- sshkey persist
- sudo backdoor on .bashrc file
- systemd timer (root only)
- SUID bin creation (root only)


## Privesc
if the target falls for the fake sudo alias, a file will be created in $HOME/.local/share with the root password and will be added SUID permissions to python, which you could use the following command to get root permissions: 

```sh
$(which python) -c 'import os; os.execl("/bin/sh", "sh", "-p")'
```

## How to use

- change variables in first lines at install.sh
- run install.sh

after the use, remove persistences running remove.sh with the user you used

### References
- https://github.com/swisskyrepo/PayloadsAllTheThings
- https://gtfobins.github.io/
- https://opensource.com/article/20/7/systemd-timers
