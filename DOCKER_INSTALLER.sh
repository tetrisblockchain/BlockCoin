#!/bin/sh
#Version 0.1.1.2
#Info: Installs BlockCoind daemon, Masternode based on privkey, and a simple web monitor.
#BlockCoin Version 0.12.1 or above
#Tested OS: Ubuntu 17.04, 16.04, and 14.04
#TODO: make script less "ubuntu" or add other linux flavors
#TODO: remove dependency on sudo user account to run script (i.e. run as root and specifiy BlockCoin user so BlockCoin user does not require sudo privileges)
#TODO: add specific dependencies depending on build option (i.e. gui requires QT4)


noflags() {
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    echo "Usage: install-blcn [options]"
    echo "Valid options are:"
    echo "MASTERNODE_PRIVKEY(Required)"
    echo "Example: install-blcn 6uQoYPjwCs6yknDS9g88XCUnVzcYF6EwXFwZC2JaidKB3x5PAFX"
    echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    exit 1
}

message() {
	echo "╒════════════════════════════════════════════════════════════════════════════════>>"
	echo "| $1"
	echo "╘═══════════════════════════════════════════════════════════════════════════════<<<"
}

error() {
	message "An error occured, you must fix it to continue!"
	exit 1
}

success() {
	#variable later
	BlockCoind
	message "SUCCESS! Your BlockCoin server has started."
	exit 0
}

prepdependencies() { #TODO: add error detection
	message "Installing BlockCoin dependencies..."
    sudo fallocate -l 2G /swapfile
    sudo chown root:root /swapfile
    sudo chmod 0600 /swapfile
    sudo bash -c "echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
    sudo mkswap /swapfile
    sudo swapon /swapfile    
	sudo apt-get update
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
	sudo apt-get install automake libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common python-software-properties g++ bsdmainutils libevent-dev -y
	sudo apt-get update
	sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}


clonerepo() { #TODO: add error detection
	message "Cloning BlockCoin from github repository..."
  	cd ~/
	#variable later
	git clone https://github.com/tetrisblockchain/BlockCoin.git
}

compile() {

	cd BlockCoin/src/leveldb #TODO: squash relative path
	message "Preparing to build BlockCoin..."
	chmod +x build_detect_platform
    make clean
    make libleveldb.a libmemenv.a
	if [ $? -ne 0 ]; then error; fi
	message "Building BlockCoin...this may take a few minutes..."
    cd ../
	make -f makefile.unix
	if [ $? -ne 0 ]; then error; fi
	message "Installing BlockCoin..."
	strip BlockCoind
    cp BlockCoind /usr/bin
	if [ $? -ne 0 ]; then error; fi
}

createconf() {
	#TODO: Can check for flag and skip this
	#TODO: Random generate the user and password

	#variable later
	coin=BlockCoin
	message "Creating $coin.conf..."

	
	CONFDIR=~/.BlockCoin
	if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
	if [ $? -ne 0 ]; then error; fi
	
	mnip=$(curl -s https://api.ipify.org)
	rpcuser=$(date +%s | sha256sum | base64 | head -c 10 ; echo)
	rpcpass=$(openssl rand -base64 32)
	printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=512" "blockcoin_node=1" > $CONFDIR/$coin.conf

}

createhttp() {
	cd ~/
	mkdir web
	cd web
	wget https://raw.githubusercontent.com/chaoabunga/mnscripts/master/index.html
	wget https://raw.githubusercontent.com/chaoabunga/mnscripts/master/stats.txt
	(crontab -l 2>/dev/null; echo "* * * * * echo MN Count:  > ~/web/stats.txt; /usr/local/bin/BlockCoin-cli masternode count >> ~/web/stats.txt; /usr/bin/BlockCoind getinfo >> ~/web/stats.txt") | crontab -
	mnip=$(curl -s https://api.ipify.org)
	sudo python3 -m http.server 8000 --bind $mnip 2>/dev/null &
	echo "BlockCoin Web Server Started!  You can now access your stats page at http://$mnip:8000"
}

install() {
	prepdependencies
	createswap
	clonerepo
	compile $1
	createconf
	#createhttp
	success
}


install
