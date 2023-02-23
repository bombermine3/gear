#!/bin/bash

curl -s https://raw.githubusercontent.com/bombermine3/cryptohamster/main/logo.sh | bash && sleep 1

if [ $# -ne 1 ]; then 
	echo "Использование:"
	echo "gear.sh <command>"
	echo "	install   Установка ноды"
	echo "	uninstall Удаление"
	echo "	update    Обновление"
	echo "	backup    Бэкап приватного ключа"
	echo ""
fi

case "$1" in
install)
	cd $HOME  
	apt update && apt -y upgrade && apt -y install wget
        wget https://get.gear.rs/gear-nightly-linux-x86_64.tar.xz
	tar xvf gear-nightly-linux-x86_64.tar.xz
	rm gear-nightly-linux-x86_64.tar.xz
	mv gear /usr/local/bin
	read -p "Введите имя ноды: " GEAR_NODE_NAME
	echo 'export GEAR_NODE_NAME="'${GEAR_NODE_NAME}'"' >> $HOME/.bash_profile
	source $HOME/.bash_profile
	printf "[Unit]
Description=Gear Node
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/usr/local/bin/gear --name \"$GEAR_NODE_NAME\" --telemetry-url \"ws://telemetry-backend-shard.gear-tech.io:32001/submit 0\"
Restart=always
RestartSec=3
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gear-node.service
	systemctl daemon-reload
	systemctl enable gear-node
	systemctl start gear-node

	echo "Установка завершена"
	echo "Проверка логов: journalctl -u gear-node -f -o cat"
        
	echo "Сделайте бэкап приватных ключей: bash gear.sh backup"
	;;
uninstall)
	systemctl stop gear-node
	systemctl disable gear-node
	rm /etc/systemd/system/gear-node.service
	rm /usr/local/bin/gear
	rm -rf /root/.local/share/gear

	echo "Удаление завершено"
	;;
update)
	cd $HOME
	wget https://get.gear.rs/gear-nightly-linux-x86_64.tar.xz
	tar -xvf gear-nightly-linux-x86_64.tar.xz -C /usr/local/bin
	rm gear-nightly-linux-x86_64.tar.xz
	systemctl stop gear-node
	mkdir -p /root/.local/share/gear/chains/gear_staging_testnet_v6/network
	cp /root/.local/share/gear/chains/gear_staging_testnet_v5/network/* /root/.local/share/gear/chains/gear_staging_testnet_v6/network/
	systemctl start gear-node

	echo "Обновление завершено"
	;;
backup)
	mkdir /root/gear_backup > /dev/null 2>&1
	cd /root/gear_backup
	hexdump -e '1/1 "%02x"' /root/.local/share/gear/chains/gear_staging_testnet_v6/network/secret_ed25519 > private.txt
	cp /root/.local/share/gear/chains/gear_staging_testnet_v6/network/secret_ed25519 ./secret_ed25519
	echo "Бэкап приватных ключей находится в /root/gear_backup"
	;;
esac

