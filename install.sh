#!/bin/bash

###############################################################################################################################################################################################################
# IF PLANNING TO RUN ZELNODE FROM HOME/OFFICE/PERSONAL EQUIPMENT & NETWORK!!!
# You must understand the implications of running a ZelNode on your on equipment and network. There are many possible security issues. DYOR!!!
# Running a ZelNode from home should only be done by those with experience/knowledge of how to set up the proper security.
# It is recommended for most operators to use a VPS to run a ZelNode
#
# **Potential Issues (not an exhaustive list):**
# 1. Your home network IP address will be displayed to the world. Without proper network security in place, a malicious person sniff around your IP for vulnerabilities to access your network.
# 2. Port forwarding: The p2p port for ZelCash will need to be open.
# 3. DDOS: VPS providers typically provide mitigation tools to resist a DDOS attack, while home networks typically don't have these tools.
# 4. Zelcash daemon is ran with sudo permissions, meaning the daemon has elevated access to your system. **Do not run a ZelNode on equipment that also has a funded wallet loaded.**
# 5. Static vs. Dynamic IPs: If you have a revolving IP, every time the IP address changes, the ZelNode will fail and need to be stood back up.
# 6. Home connections typically have a monthly data cap. ZelNodes will use 2.5 - 6 TB monthly usage depending on ZelNode tier, which can result in overage charges. Check your ISP agreement.
# 7. Many home connections provide adequate download speeds but very low upload speeds. ZelNodes require 100mbps (12.5MB/s) download **AND** upload speeds. Ensure your ISP plan can provide this continually. 
# 8. ZelNodes can saturate your network at times. If you are sharing the connection with other devices at home, its possible to fail a benchmark if network is saturated.
###############################################################################################################################################################################################################

###### you must be logged in as a sudo user, not root #######

COIN_NAME='zelcash'

#wallet information

UPDATE_FILE='update.sh'
#BOOTSTRAP_ZIP='http://77.55.218.93/zel-bootstrap3.zip'
BOOTSTRAP_ZIP='https://www.dropbox.com/s/kyqe8ji3g1yetfx/zel-bootstrap.zip'
BOOTSTRAP_ZIPFILE='zel-bootstrap.zip'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'
RPCPORT='16124'
PORT='16125'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
USERNAME="$(whoami)"
IMPORT_ZELCONF="0"
IMPORT_ZELID="0"

#Zelflux ports
ZELFRONTPORT=16126
LOCPORT=16127
ZELNODEPORT=16128
MDBPORT=27017


#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
#dialog color
export NEWT_COLORS='
title=black,
'


function import_date() {

if [[ -f ~/.zelcash/zelcash.conf ]]
then
if whiptail --yesno "Would you like to import data from zelcash.conf Y/N?" 8 60; then
IMPORT_ZELCONF="1"
echo
echo -e "${SEA}Imported settings:${NC}"
zelnodeprivkey=$(grep -w zelnodeprivkey ~/.zelcash/zelcash.conf | sed -e 's/zelnodeprivkey=//')
echo -e "${PIN} ${CYAN}Private Key = ${GREEN}$zelnodeprivkey${NC}"
zelnodeoutpoint=$(grep -w zelnodeoutpoint ~/.zelcash/zelcash.conf | sed -e 's/zelnodeoutpoint=//')
echo -e "${PIN} ${CYAN}Output TX ID = ${GREEN}$zelnodeoutpoint${NC}"
zelnodeindex=$(grep -w zelnodeindex ~/.zelcash/zelcash.conf | sed -e 's/zelnodeindex=//') 
echo -e "${PIN} ${CYAN}Output Index = ${GREEN}$zelnodeindex${NC}"
fi
fi


if [[ -f ~/zelflux/config/userconfig.js ]]
then
if whiptail --yesno "Would you like to import zelid from userconfig.js Y/N?" 8 60; then
IMPORT_ZELID="1"
ZELID=$(grep -w zelid ~/zelflux/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
echo -e "${PIN} ${CYAN}Zel ID = ${GREEN}$ZELID${NC}"
fi
fi
sleep 2
echo
}

#end of required details
#
#Suppressing password prompts for this user so zelnode can operate
sudo echo -e "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
echo -e "${CYAN}APRIL 2020, created by dk808 improved by XK4MiLX from Zel's team and AltTank Army."
echo -e "Special thanks to Goose-Tech, Skyslayer, & Packetflow."
echo -e "Zelnode setup starting, press [CTRL+C] to cancel.${NC}"
sleep 3
if [ "$USERNAME" = "root" ]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}root${CYAN}, please switch to the username you just created.${NC}"
    sleep 4
    exit
fi

start_dir=$(pwd)
correct_dir="/home/$USER"
echo
echo -e "${YELLOW}Checking directory....${NC}"
if [[ "$start_dir" == "$correct_dir" ]]
then
echo -e "${CHECK_MARK} ${CYAN}Correct directory...${NC}"
else
echo -e "${X_MARK} ${CYAN}Bad directory switching...${NC}"
cd
echo -e "${YELLOW}$(pwd)${NC}"
fi
sleep 1

import_date

#functions
function install_watchdog() {
echo -e ""
echo -e "${GREEN}Install watchdog for zelnode${NC}"
echo -e "${YELLOW}================================================================${NC}"

if pm2 -v > /dev/null 2>&1
then
echo -e "${YELLOW}Downloading...${NC}"
cd && git clone https://github.com/XK4MiLX/watchdog.git
echo -e "${YELLOW}Installing git hooks....${NC}"
wget https://raw.githubusercontent.com/XK4MiLX/zelnode/master/post-merge
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge 
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge 
echo -e "${YELLOW}Installing watchdog module....${NC}"
cd watchdog && npm install
echo -e "${YELLOW}Starting watchdog...${NC}"
pm2 start ~/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch "\.git|node_modules|watchdog_error.log|config.js" --watch-delay 10
pm2 save
if [[ -f ~/watchdog/watchdog.js ]]
then
echo -e "${CHECK_MARK} ${CYAN}Watchdog installed successful.${NC}"
else
echo -e "${X_MARK} ${CYAN}Watchdog installion failed.${NC}"
fi
else
echo -e "${X_MARK} ${CYAN}Watchdog installion failed.${NC}"
fi

}



function mongodb_bootstrap(){

echo -e ""
echo -e "${GREEN}Restore Mongodb datatable from bootstrap${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${NC}"
pm2 stop zelflux > /dev/null 2>&1 && sleep 2
pm2 start zelflux > /dev/null 2>&1 && sleep 2
NUM='120'
MSG1='Zelflux loading...'
MSG2="${CHECK_MARK}"
spinning_timer
DB_HIGHT=572200
IP=$(wget http://ipecho.net/plain -O - -q)
BLOCKHIGHT=$(wget -nv -qO - http://"$IP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')

echo -e "${PIN} ${CYAN}IP: ${PINK}$IP"
echo -e "${PIN} ${CYAN}Node block hight: ${GREEN}$BLOCKHIGHT${NC}"
echo -e "${PIN} ${CYAN}Bootstrap block hight: ${GREEN}$DB_HIGHT${NC}"
echo -e ""
if [[ "$BLOCKHIGHT" -gt "0" && "$BLOCKHIGHT" -lt "$DB_HIGHT" ]]
then
echo -e "${YELLOW}Downloading db for mongo...${NC}"
wget http://77.55.218.93/fluxdb_dump.tar.gz
echo -e "${YELLOW}Unpacking...${NC}"
tar xvf fluxdb_dump.tar.gz -C /home/$USER && sleep 1
echo -e "${YELLOW}Stoping zelflux...${NC}"
pm2 stop zelflux > /dev/null 2>&1
echo -e "${YELLOW}Importing mongo db...${NC}"
mongorestore --port 27017 --db zelcashdata /home/$USER/dump/zelcashdata --drop
echo -e "${YELLOW}Cleaning...${NC}"
sudo rm -rf /home/$USER/dump && sleep 1
sudo rm -rf fluxdb_dump.tar.gz && sleep 1
pm2 start zelflux > /dev/null 2>&1
pm2 save > /dev/null 2>&1

NUM='120'
MSG1='Zelflux starting...'
MSG2="${CHECK_MARK}"
spinning_timer
echo
BLOCKHIGHT_AFTER_BOOTSTRAP=$(wget -nv -qO - http://"$IP":16127/explorer/scannedheight | jq '.data.generalScannedHeight')
echo -e ${PIN} ${CYAN}Node block hight after restored: ${GREEN}$BLOCKHIGHT_AFTER_BOOTSTRAP${NC}
if [[ "$BLOCKHIGHT_AFTER_BOOTSTRAP" -ge  "$DB_HIGHT" ]] 
then
echo -e "${CHECK_MARK} ${CYAN}Mongo bootstrap installed successful.${NC}"
echo -e ""
else
echo -e "${X_MARK} ${CYAN}Mongo bootstrap installation failed.${NC}"
echo -e ""
fi
else
echo -e "${X_MARK} ${CYAN}Current Node block hight ${RED}$BLOCKHIGHT${CYAN} > Bootstrap block hight ${RED}$DB_HIGHT${CYAN}. Datatable is out of date.${NC}"
echo -e ""
fi

}

function wipe_clean() {
    echo -e "${YELLOW}Removing any instances of ${COIN_NAME^}${NC}"
    "$COIN_CLI" stop > /dev/null 2>&1 && sleep 2
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo killall -s SIGKILL $COIN_DAEMON > /dev/null 2>&1 && sleep 2
    zelbench-cli stop > /dev/null 2>&1 && sleep 2
    sudo killall -s SIGKILL zelbenchd > /dev/null 2>&1 && sleep 1
    sudo fuser -k 16127/tcp > /dev/null 2>&1 && sleep 1
    sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
    sudo rm -rf  ${COIN_PATH}/zel* > /dev/null 2>&1 && sleep 1
    sudo rm -rf /usr/bin/${COIN_NAME}* > /dev/null 2>&1 && sleep 1
    sudo rm -rf /usr/local/bin/zel* > /dev/null 2>&1 && sleep 1
    sudo apt-get remove zelcash zelbench -y > /dev/null 2>&1 && sleep 1
    sudo apt-get purge zelcash zelbench -y > /dev/null 2>&1 && sleep 1
    sudo apt-get autoremove -y > /dev/null 2>&1 && sleep 1
    sudo rm -rf /etc/apt/sources.list.d/zelcash.list > /dev/null 2>&1 && sleep 1
    tmux kill-server > /dev/null 2>&1 && sleep 1  
    pm2 del zelflux > /dev/null 2>&1 && sleep 1
    pm2 del watchdog > /dev/null 2>&1 && sleep 1
    pm2 save > /dev/null 2>&1
    pm2 unstartup > /dev/null 2>&1 && sleep 1 
    pm2 flush > /dev/null 2>&1 && sleep 1
    pm2 save > /dev/null 2>&1 && sleep 1
    pm2 kill > /dev/null 2>&1  && sleep 1
    sudo npm remove pm2 -g > /dev/null 2>&1 && sleep 1
    sudo rm -rf watchgod > /dev/null 2>&1 && sleep 1
    sudo rm -rf zelflux > /dev/null 2>&1  && sleep 1
    sudo rm -rf ~/$CONFIG_DIR/determ_zelnodes ~/$CONFIG_DIR/sporks ~/$CONFIG_DIR/database ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate && sleep 2
    sudo rm -rf .zelbenchmark && sleep 1
    ## rm -rf $BOOTSTRAP_ZIPFILE && sleep 1
    rm $UPDATE_FILE > /dev/null 2>&1
    rm restart_zelflux.sh > /dev/null 2>&1
    rm zelnodeupdate.sh > /dev/null 2>&1
    rm start.sh > /dev/null 2>&1
    rm update-zelflux.sh > /dev/null 2>&1
    sudo rm -rf /home/$USER/.zelcash  > /dev/null 2>&1 && sleep 2
    sudo rm /home/$USER/fluxdb_dump.tar.gz > /dev/null 2>&1
    sudo rm -rf /home/$USER/watchdog > /dev/null 2>&1
    
    
    
    if [ ! -d "/home/$USER/$CONFIG_DIR" ]; then
    	echo -e "${CHECK_MARK} ${CYAN} Config directory /home/$USER/$CONFIG_DIR cleaned [OK]${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Config directory /home/$USER/$CONFIG_DIR cleaned [Failed]${NC}" && sleep 1
    fi
    
    if ! ls '/usr/local/bin/' | grep zel > /dev/null 2>&1 ; then
    	echo -e "${CHECK_MARK} ${CYAN} Bin directory cleaned [OK]${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Bin directory cleaned [Failed]${NC}" && sleep 1
    fi
   
    
    echo
    echo -e "${YELLOW}Detecting Firewall status...${NC}" && sleep 1
    if [[ $(sudo ufw status | grep "Status: active") ]]
    then
    
    echo -e "${YELLOW}Firewall enabled...${NC}" 
    if   whiptail --yesno "Firewall is active and enabled. Do you want disable it during install process?<Yes>(Recommended)" 8 60; then
    	 sudo ufw disable	
    fi
    
    else
    	echo -e "${YELLOW}Firewall disabled...${NC}"	
    fi
}

function spinning_timer() {
    animation=( ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? )
    end=$((SECONDS+NUM))
    while [ $SECONDS -lt $end ];
    do
        for i in "${animation[@]}";
        do
            echo -ne "${RED}\r$i ${CYAN}${MSG1}${NC}"
            sleep 0.1
        done
    done
    echo -e "${MSG2}"
}

function ssh_port() {
    echo -e "${YELLOW}Detecting SSH port being used...${NC}" && sleep 1
    SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
    if ! whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56; then
        SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    else
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    fi
}

function ip_confirm() {
    echo -e "${YELLOW}Detecting IP address being used...${NC}" && sleep 1
    WANIP=$(wget http://ipecho.net/plain -O - -q)
    if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
    	WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
    fi
}

function create_swap() {
    echo -e "${YELLOW}Creating swap if none detected...${NC}" && sleep 1
    MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    gb=$(awk "BEGIN {print $MEM/1048576}")
    GB=$(echo "$gb" | awk '{printf("%d\n",$1 + 0.5)}')
    if [ "$GB" -lt 2 ]; then
    	(( swapsize=GB*2 ))
	swap="$swapsize"G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -ge 2 ]] && [[ $GB -le 16 ]]; then
    	swap=4G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    elif [[ $GB -gt 16 ]] && [[ $GB -lt 32 ]]; then
    	swap=2G
	echo -e "${YELLOW}Swap set at $swap...${NC}"
    fi
    if ! grep -q "swapfile" /etc/fstab; then
    	if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
	    sudo fallocate -l "$swap" /swapfile
	    sudo chmod 600 /swapfile
	    sudo mkswap /swapfile
	    sudo swapon /swapfile
	    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
	    echo -e "${YELLOW}Created ${SEA}${swap}${YELLOW} swapfile${NC}"
	else
	    echo -e "${YELLOW}You have opted out on creating a swapfile so no swap created...${NC}"
	fi
    fi
    sleep 2
}

function install_packages() {
    echo -e "${YELLOW}Installing Packages...${NC}"
    if [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
    	sudo apt-get install dirmngr apt-transport-https -y
    fi
    sudo apt-get install software-properties-common -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install nano htop pwgen ufw figlet tmux jq -y
    sudo apt-get install build-essential libtool pkg-config -y
    sudo apt-get install libc6-dev m4 g++-multilib -y
    sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y
    sudo apt-get install wget curl bsdmainutils automake fail2ban -y
    sudo apt-get remove sysbench -y
    echo -e "${YELLOW}Packages complete...${NC}"
}

function create_conf() {
    echo -e "${YELLOW}Creating Conf File...${NC}"
    if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
    	echo -e "${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
	mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
    fi
    RPCUSER=$(pwgen -1 8 -n)
    PASSWORD=$(pwgen -1 20 -n)
    
    if [[ "$IMPORT_ZELCONF" == "0" ]]
    then
    zelnodeprivkey=$(whiptail --title "ZELNODE PRIVKEY" --inputbox "Enter your Zelnode Privkey generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)
    zelnodeoutpoint=$(whiptail --title "ZELNODE OUTPOINT" --inputbox "Enter your Zelnode collateral txid" 8 72 3>&1 1>&2 2>&3)
    zelnodeindex=$(whiptail --title "ZELNODE INDEX" --inputbox "Enter your Zelnode collateral output index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
    fi


    if [ "x$PASSWORD" = "x" ]; then
    	PASSWORD=${WANIP}-$(date +%s)
    fi
    mkdir ~/$CONFIG_DIR > /dev/null 2>&1
    touch ~/$CONFIG_DIR/$CONFIG_FILE
    cat << EOF > ~/$CONFIG_DIR/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcallowip=172.18.0.1
rpcport=$RPCPORT
port=$PORT
zelnode=1
zelnodeprivkey=$zelnodeprivkey
zelnodeoutpoint=$zelnodeoutpoint
zelnodeindex=$zelnodeindex
server=1
daemon=1
txindex=1
listen=1
bind=$WANIP
externalip=$WANIP
addnode=explorer.zel.cash
addnode=explorer2.zel.cash
addnode=explorer.zel.zelcore.io
addnode=blockbook.zel.network
maxconnections=256
EOF
    sleep 2
}

function zel_package() {
    sudo apt-get update
    sudo apt install zelcash zelbench -y
    sudo chmod 755 $COIN_PATH/${COIN_NAME}*
}

function install_zel() {
    echo -e "${YELLOW}==========================================================================${NC}"
    echo -e "${GREEN}ZELCASH, ZELBENCH INSTALLATION${NC}"
    echo -e "${YELLOW}==========================================================================${NC}"
    echo 'deb https://apt.zel.cash/ all main' | sudo tee /etc/apt/sources.list.d/zelcash.list
    sleep 1
    if [ ! -f /etc/apt/sources.list.d/zelcash.list ]; then
    	echo 'deb https://zelcash.github.io/aptrepo/ all main' | sudo tee --append /etc/apt/sources.list.d/zelcash.list
    fi
    gpg --keyserver keyserver.ubuntu.com --recv 4B69CA27A986265D
    gpg --export 4B69CA27A986265D | sudo apt-key add -
    zel_package && sleep 2
    if ! gpg --list-keys Zel > /dev/null; then
    	echo -e "${YELLOW}First attempt to retrieve keys failed will try a different keyserver.${NC}"
	gpg --keyserver na.pool.sks-keyservers.net --recv 4B69CA27A986265D
	gpg --export 4B69CA27A986265D | sudo apt-key add -
	zel_package && sleep 2
	if ! gpg --list-keys Zel > /dev/null; then
	    echo -e "${YELLOW}Second keyserver also failed will try a different keyserver.${NC}"
	    gpg --keyserver eu.pool.sks-keyservers.net --recv 4B69CA27A986265D
	    gpg --export 4B69CA27A986265D | sudo apt-key add -
	    zel_package && sleep 2
	    if ! gpg --list-keys Zel > /dev/null; then
	    	echo -e "${YELLOW}Third keyserver also failed will try a different keyserver.${NC}"
		gpg --keyserver pgpkeys.urown.net --recv 4B69CA27A986265D
		gpg --export 4B69CA27A986265D | sudo apt-key add -
		zel_package && sleep 2
		if ! gpg --list-keys Zel > /dev/null; then
		    echo -e "${YELLOW}Last keyserver also failed will try one last keyserver.${NC}"
		    gpg --keyserver keys.gnupg.net --recv 4B69CA27A986265D
		    gpg --export 4B69CA27A986265D | sudo apt-key add -
		    zel_package && sleep 2
		fi
	    fi
	fi
    fi
}

function zk_params() {
    echo -e "${YELLOW}Installing zkSNARK params...${NC}"
    bash zelcash-fetch-params.sh
    sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
}

function bootstrap() {

echo -e "${NC}"
if [[ -e ~/$CONFIG_DIR/blocks ]] && [[ -e ~/$CONFIG_DIR/chainstate ]]; then
echo -e "${YELLOW}Cleaning...${NC}"
rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate	
fi 


if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]
then
echo -e "${YELLOW}Local bootstrap file detected...${NC}"
echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"

#lsof +d /home/$USER/.zelcash
#sleep 4

unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
else

echo -e ""
echo -e "${YELLOW}================================================================${NC}"
echo -e "${RED}Choose a method how to get bootstrap file${NC}"
echo -e "${YELLOW}================================================================${NC}"
echo -e "${NC}1 - Download from source build in script${NC}"
echo -e "${NC}2 - Download from own source${NC}"
echo -e "${YELLOW}================================================================${NC}"
read -p "Pick an option: " -n 1 -r
echo -e "${NC}"
while true

do
    case "$REPLY" in

    1 ) 

	echo -e "${YELLOW}Downloading File: $BOOTSTRAP_ZIP ${NC}"
	wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP
	echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"
	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
	break
;;
    2 )
    
	BOOTSTRAP_ZIP="$(whiptail --title "ZelNode Installer" --inputbox "Enter your URL" 8 72 3>&1 1>&2 2>&3)"
	echo -e "${YELLOW}Downloading File: $BOOTSTRAP_ZIP ${NC}"
	wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP
	echo -e "${YELLOW}Installing wallet bootstrap please be patient...${NC}"
	unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR
	break
;;

     *) echo "Invalid option $REPLY try again...";;

    esac

done


fi
echo -e "${NC}"
read -p "Would you like remove bootstrap file Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
rm -rf $BOOTSTRAP_ZIPFILE
fi

}

function create_service() {
    echo -e "${YELLOW}Creating ${COIN_NAME^} service...${NC}"
    sudo touch /etc/systemd/system/$COIN_NAME.service
    sudo chown "$USERNAME":"$USERNAME" /etc/systemd/system/$COIN_NAME.service
    cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/$CONFIG_DIR/
ExecStart=$COIN_PATH/$COIN_DAEMON -datadir=/home/$USERNAME/$CONFIG_DIR/ -conf=/home/$USERNAME/$CONFIG_DIR/$CONFIG_FILE -daemon
ExecStop=-$COIN_PATH/$COIN_CLI stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
    sudo chown root:root /etc/systemd/system/$COIN_NAME.service
    sudo systemctl daemon-reload 
    sudo systemctl enable $COIN_NAME.service > /dev/null 2>&1
    sudo systemctl start zelcash
    
}

function basic_security() {
    echo -e "${YELLOW}Configuring firewall and enabling fail2ban...${NC}" 
    sudo ufw allow "$SSHPORT"/tcp
    sudo ufw allow "$PORT"/tcp
    sudo ufw logging on
    sudo ufw default deny incoming
    sudo ufw limit OpenSSH    
    echo "y" | sudo ufw enable > /dev/null 2>&1  
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
}

function start_daemon() {
    NUM='105'
    MSG1='Starting daemon & syncing with chain please be patient this will take about 2 min...'
    MSG2=''
    if $COIN_DAEMON > /dev/null 2>&1; then
    	echo && spinning_timer
	NUM='10'
	MSG1='Getting info...'
	MSG2="${CHECK_MARK}"
	echo && spinning_timer
	echo
	$COIN_CLI getinfo
	sleep 5
    else
    	echo -e "${RED}Something is not right the daemon did not start. Will exit out so try and run the script again.${NC}"
	exit
    fi
}

function log_rotate() {
    echo -e "${YELLOW}Configuring log rotate function for debug logs...${NC}"
    sleep 1
    if [ -f /etc/logrotate.d/zeldebuglog ]; then
        echo -e "${YELLOW}Existing log rotate conf found, backing up to ~/zeldebuglogrotate.old ...${NC}"
	sudo mv /etc/logrotate.d/zeldebuglog ~/zeldebuglogrotate.old;
	sleep 2
    fi
    sudo touch /etc/logrotate.d/zeldebuglog
    sudo chown "$USERNAME":"$USERNAME" /etc/logrotate.d/zeldebuglog
    cat << EOF > /etc/logrotate.d/zeldebuglog
/home/$USERNAME/.zelcash/debug.log {
  compress
  copytruncate
  missingok
  weekly
  rotate 4
}

/home/$USERNAME/.zelbenchmark/debug.log {
  compress
  copytruncate
  missingok
  monthly
  rotate 2
}
EOF
    sudo chown root:root /etc/logrotate.d/zeldebuglog
}

function install_zelflux() {
    echo -e "${YELLOW}==========================================================================${NC}"
    echo -e "${GREEN}PREPERING FOR MONGODB, NODEJS, ZELFLUX INSTALLATION${NC}"
    echo -e "${YELLOW}==========================================================================${NC}"
    sudo ufw allow $ZELFRONTPORT/tcp 
    sudo ufw allow $LOCPORT/tcp
    sudo ufw allow $ZELNODEPORT/tcp
    sudo ufw allow $MDBPORT/tcp
    
    if ! sysbench --version > /dev/null 2>&1; then   
   	curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
	sudo apt -y install sysbench > /dev/null 2>&1
    fi
    
    sudo rm /etc/apt/sources.list.d/mongodb*.list > /dev/null 2>&1
    if [[ $(lsb_release -r) = *16.04* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -r) = *18.04* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    elif [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *10* ]]; then
    	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	install_mongod
	install_nodejs
	zelflux
    fi
    sleep 2
}

function install_mongod() {
echo -e "${YELLOW}==========================================================================${NC}"
echo -e "${GREEN}MONGODB INSTALLATION${NC}"
echo -e "${YELLOW}==========================================================================${NC}"
echo -e "${YELLOW}Removing any instances of Mongodb...${NC}"
sudo apt remove mongod* -y > /dev/null 2>&1 && sleep 1
sudo apt purge mongod* -y > /dev/null 2>&1 && sleep 1
sudo apt autoremove -y > /dev/null 2>&1 && sleep 1
echo -e "${YELLOW}Mongodb installing...${NC}"
sudo apt-get update -y
sudo apt-get install mongodb-org -y
sudo systemctl enable mongod
sudo systemctl start  mongod
}

function install_nodejs() {
echo -e "${YELLOW}==========================================================================${NC}"
echo -e "${GREEN}NODEJS AND NPM INSTALLATION${NC}"
echo -e "${YELLOW}==========================================================================${NC}"
echo -e "${YELLOW}Removing any instances of Nodejs...${NC}"
n-uninstall -y > /dev/null 2>&1 && sleep 1
rm -rf ~/n
sudo apt-get remove nodejs npm nvm -y > /dev/null 2>&1 && sleep 1
sudo apt-get purge nodejs nvm -y > /dev/null 2>&1 && sleep 1
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node*
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm
sudo rm -rf ~/.nvm
sudo rm -rf ~/.pm2
sudo rm -rf ~/.node-gyp
sudo rm -rf /opt/local/bin/node
sudo rm -rf opt/local/include/node
sudo rm -rf /opt/local/lib/node_modules
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf /usr/local/bin/node*
echo -e "${YELLOW}Nodejs installing...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
. ~/.profile
#nvm install --lts
nvm install v12.16.1
}

function zelflux() {

   echo -e "${YELLOW}==========================================================================${NC}"
   echo -e "${GREEN}ZELFLUX INSTALLATION${NC}"
   echo -e "${YELLOW}==========================================================================${NC}" 
    if [ -d "./zelflux" ]; then
    	 echo -e "${YELLOW}Cleaning old installation....${NC}"
    	sudo rm -rf zelflux
    fi
   	
	if [[ "$IMPORT_ZELID" == "0" ]]
	then
	
	while true
		do
		ZELID="$(whiptail --title "ZelFlux Configuration" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
		if [ $(printf "%s" "$ZELID" | wc -c) -eq "34" ] || [ $(printf "%s" "$ZELID" | wc -c) -eq "33" ]
		then
		echo -e "${CHECK_MARK} ${CYAN}Zel ID is valid${NC}"
		break
		else
		echo -e "${X_MARK} ${CYAN}Zel ID is not valid try again...${NC}"
		sleep 4
		fi
	done
	
	fi
		    
    echo -e "${YELLOW}Downloading....${NC}"
    git clone https://github.com/zelcash/zelflux.git
    echo -e "${YELLOW}Creating zelflux configuration file...${NC}"
    touch ~/zelflux/config/userconfig.js
    cat << EOF > ~/zelflux/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
	zelid: '${ZELID}',
	testnet: false
      }
    }
EOF

   echo -e "${YELLOW}==========================================================================${NC}"
   echo -e "${GREEN}PROCESS MANAGER FOR NODEJS INSTALLATION${NC}"
   echo -e "${YELLOW}==========================================================================${NC}"

   #if pm2 -v > /dev/null 2>&1; then  
   #echo -e "${YELLOW}Cleaning old installation....${NC}"
   #pm2 kill > /dev/null 2>&1
   #npm remove pm2 -g > /dev/null 2>&1
   #echo -e "${YELLOW}Installing...${NC}"
   #npm i -g pm2 > /dev/null 2>&1
  # else
   echo -e "${YELLOW}Installing...${NC}"
   npm i -g pm2 > /dev/null 2>&1
   #fi
  
    echo -e "${YELLOW}Configuring PM2...${NC}"
    # pm2 startup systemd -u $USERNAME
    # sudo env PATH=$PATH:/home/$USERNAME/.nvm/versions/node/v12.16.1/bin pm2 startup systemd -u $USERNAME --hp /home/$USERNAME
    cmd=$(pm2 startup systemd -u $USER | grep sudo)
    sudo bash -c "$cmd"
    pm2 start ~/zelflux/start.sh --name zelflux
    pm2 save
    pm2 install pm2-logrotate
    pm2 set pm2-logrotate:max_size 6M >/dev/null
    pm2 set pm2-logrotate:retain 6 >/dev/null
    pm2 set pm2-logrotate:compress true >/dev/null
    pm2 set pm2-logrotate:workerInterval 3600 >/dev/null
    pm2 set pm2-logrotate:rotateInterval '0 12 * * 0' >/dev/null
    source ~/.bashrc
}
	
function status_loop() {

if [[ $(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks') == $(${COIN_CLI} getinfo | jq '.blocks') ]]; then

echo -e "${YELLOW}======================================================================================"
echo -e "${GREEN} ZELNODE IS SYNCING..."
echo -e " CHECK BLOCK HEIGHT AT https://explorer.zel.cash/"
echo -e " YOU COULD START YOUR ZELNODE FROM YOUR CONTROL WALLET WHILE IT SYNCS"
echo -e "${YELLOW}======================================================================================${NC}"
echo
echo -e "${CYAN}ZelNode is already synced.${NC}${CHECK_MARK}"
echo
$COIN_CLI getinfo
sleep 2
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

else

    while true
    do
    	clear
	echo -e "${YELLOW}======================================================================================"
	echo -e "${GREEN} ZELNODE IS SYNCING"
	echo -e " THIS SCREEN REFRESHES EVERY 30 SECONDS"
	echo -e " CHECK BLOCK HEIGHT AT https://explorer.zel.cash/"
	echo -e " YOU COULD START YOUR ZELNODE FROM YOUR CONTROL WALLET WHILE IT SYNCS"
	echo -e "${YELLOW}======================================================================================${NC}"
	echo
	$COIN_CLI getinfo
	sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
	NUM='30'
	MSG1="${CYAN}Refreshes every 30 seconds while syncing to chain. Refresh loop will stop automatically once it's fully synced.${NC}"
	MSG2=''
	spinning_timer
	
	EXPLORER_BLOCK_HIGHT=$(wget -nv -qO - https://explorer.zel.cash/api/status?q=getInfo | jq '.info.blocks')
	LOCAL_BLOCK_HIGHT=$(${COIN_CLI} getinfo | jq '.blocks')
	
	
	if [[ "$EXPLORER_BLOCK_HIGHT" == "$LOCAL_BLOCK_HIGHT" ]]; then
	    break
	fi
	    
	if grep unknown <<< "$LOCAL_BLOCK_HIGHT" 
	then
	echo -e "${YELLOW}Restarting zelcash service..${NC}"
        sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
	sudo fuser -k 16125/tcp > /dev/null 2>&1
	sudo systemctl start $COIN_NAME > /dev/null 2>&1 && sleep 5
	fi
	
    done
    
    fi
    
    if   whiptail --yesno "Would you like to restore Mongodb datatable from bootstrap?" 8 60; then
    	 mongodb_bootstrap	
    else
    	echo -e "${YELLOW}Restore Mongodb datatable skipped...${NC}"	
    fi
    
    if   whiptail --yesno "Would you like to install watchdog for zelnode?" 8 60; then
    	 install_watchdog	
    else
    	echo -e "${YELLOW}Watchdog installation skipped...${NC}"	
    fi
    
    check
    display_banner
}

function update_script() {
    echo -e "${YELLOW}Creating a script to update binaries for future updates...${NC}"
    touch /home/"$USERNAME"/update.sh
    cat << EOF > /home/"$USERNAME"/update.sh
#!/bin/bash
COIN_NAME='zelcash'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
\$COIN_CLI stop > /dev/null 2>&1 && sleep 2
sudo killall \$COIN_DAEMON > /dev/null 2>&1
sudo apt-get update
sudo apt-get install --only-upgrade \$COIN_NAME -y
sudo chmod 755 \${COIN_PATH}/\${COIN_NAME}*
\$COIN_DAEMON > /dev/null 2>&1
EOF

#sudo chmod +x update.sh 
#echo "cd /home/$USER/zelflux" >> "/home/$USER/update-zelflux.sh"
#echo "git pull" >> "/home/$USER/update-zelflux.sh"
#chmod +x "/home/$USER/update-zelflux.sh"
#(crontab -l -u "$USER" 2>/dev/null; echo "0 0 * * 0 /home/$USER/update-zelflux.sh") | crontab -
 
}


function check() {
    echo
    echo -e "${YELLOW}Running through some checks...${NC}"
    
    if pgrep zelcashd > /dev/null; then
    	echo -e "${CHECK_MARK} ${CYAN}${COIN_NAME^} daemon is installed and running${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}${COIN_NAME^} daemon is not running${NC}" && sleep 1
    fi
    
    if [ -d "/home/$USERNAME/.zcash-params" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}zkSNARK params installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}zkSNARK params not installed${NC}" && sleep 1
    fi
    
    if mongod --version > /dev/null; then
    	echo -e "${CHECK_MARK} ${CYAN}Mongodb is installed and running${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Mongodb is not running or failed to install${NC}" && sleep 1
    fi
    
    if node -v > /dev/null 2>&1; then
    	echo -e "${CHECK_MARK} ${CYAN}Nodejs installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Nodejs did not install${NC}" && sleep 1
    fi
    
    if [ -d "/home/$USERNAME/zelflux" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}Zelflux installed${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Zelflux did not install${NC}" && sleep 1
    fi
    
    if [ -f "/home/$USERNAME/$UPDATE_FILE" ]; then
    	echo -e "${CHECK_MARK} ${CYAN}Update script created${NC}" && sleep 1
    else
    	echo -e "${X_MARK} ${CYAN}Update script not installed${NC}" && sleep 1
    fi
  
    NUM='140'
    MSG1='Finalizing installation please be patient this will take about 2 min...'
    MSG2="${CHECK_MARK}"
    echo && echo && spinning_timer
    echo -e "${YELLOW}Restarting benchmarks...${NC}"
    zelbench-cli restartnodebenchmarks
    NUM='35'
    MSG1='Restarting benchmarks...'
    MSG2="${CHECK_MARK}"
    echo && spinning_timer
    echo -e "${YELLOW}Checking benchmarks details...${NC}"
    zelbench-cli getbenchmarks
    
}

function display_banner() {
    echo -e "${BLUE}"
    figlet -t -k "ZELNODES  &  ZELFLUX"
    figlet -t -k "PM2  EDITION"
    echo -e "${NC}"
    echo -e "${YELLOW}================================================================================================================================"
    echo -e " PLEASE COMPLETE THE ZELNODE SETUP AND START YOUR ZELNODE${NC}"
    echo -e "${CYAN} COURTESY OF DK808/XK4MiLX${NC}"
    echo
    echo -e "${YELLOW}   Commands to manage ${COIN_NAME}. Note that you have to be in the zelcash directory when entering commands.${NC}"
    echo -e "${PIN} ${CYAN}TO START: ${SEA}${COIN_DAEMON}${NC}"
    echo -e "${PIN} ${CYAN}TO STOP : ${SEA}${COIN_CLI} stop${NC}"
    echo -e "${PIN} ${CYAN}RPC LIST: ${SEA}${COIN_CLI} help${NC}"
    echo
    echo -e "${PIN} ${YELLOW}To update binaries wait for announcement that update is ready then enter:${NC} ${SEA}./${UPDATE_FILE}${NC}"
    echo
    echo -e "${YELLOW}   PM2 is now managing Zelflux.${NC}"
    echo -e "${YELLOW}   Commands to manage PM2.${NC}"
    echo -e "${PIN} ${CYAN}Summary info: ${SEA}pm2 info zelflux${NC}"
    echo -e "${PIN} ${CYAN}Logs in real time: ${SEA}pm2 monit${NC}"
    echo
    pm2 info zelflux
    echo
    echo -e "${PIN} ${CYAN}To access your frontend to Zelflux enter this in as your url: ${SEA}${WANIP}:${ZELFRONTPORT}${NC}"
    echo -e "${YELLOW}================================================================================================================================${NC}"
    sleep 2
    read -p "Would you like to reboot pc Y/N?" -n 1 -r
    echo -e "${NC}"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
    sudo reboot -n
    fi
   
}



#end of functions
#run functions
    wipe_clean
    ssh_port
    ip_confirm
    create_swap
    install_packages
    create_conf
    install_zel
    zk_params
    bootstrap
    create_service
    start_daemon
    install_zelflux
    log_rotate
    update_script
    basic_security
    status_loop
