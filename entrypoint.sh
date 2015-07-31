#!/usr/bin/env bash

# Translates relevant docker environment values
# to configure.rb parameters
# ----------------------------------------------

add_cassandra_options () {
	local opts=""
	# if --seed is not set, set it to the alias host
	
	if [ ! $SEED_NAME ] && [[ $* != *"--seeds"* ]]; then opts="$opts --seeds "$(ip route get 255.255.255.255 | grep -Po '(?<=src )(\d{1,3}.){4}');
	elif [ $SEED_NAME ] && [[ $* != *"--seeds"* ]]; then opts="$opts --seeds seed"; fi
	# if --listen-address is not set, set it to $HOSTNAME
	if [ $HOSTNAME ] && [[ $* != *"--listen-address"* ]]; then opts="$opts --listen-address $HOSTNAME"; fi
	# if --rpc-address is not set, set it to $HOSTNAME
	if [ $HOSTNAME ] && [[ $* != *"--rpc-address"* ]]; then opts="$opts --rpc-address $HOSTNAME"; fi
	
	echo $opts
}

add_datanode_options () {
	local opts=""
	# if --name-node is not set, set it to the docker alias host
	if [ $NAMENODE_NAME ] && [ ! "$*" == *"--name-node"* ]; then opts="$opts --name-node namenode"; fi
	
	echo $opts
}

add_nodemanager_options () {
	local opts=""
	# if --resource-manager is not set, set it to the docker alias host
	if [ $RESOURCEMANAGER_NAME ] && [[ "$*" != *"--resource-manager"* ]]; then opts="$opts --resource-manager resourcemanager"; fi
	if [ $HOSTNAME ] && [[ "$*" != *"--web-ui-host"* ]]; then opts="$opts --web-ui-host $HOSTNAME"; fi
	
	echo $opts
}

case $1 in
	all) ruby /root/configure.rb $* `add_cassandra_options $*` `add_datanode_options $*` `add_nodemanager_options $*` && supervisord -c /etc/supervisord.conf ;;
	cassandra) ruby /root/configure.rb $* `add_cassandra_options $*` && supervisord -c /etc/supervisord.conf ;;
	datanode) ruby /root/configure.rb $* `add_datanode_options $*` && supervisord -c /etc/supervisord.conf ;;
	nodemanager) ruby /root/configure.rb $* `add_nodemanager_options $*` && supervisord -c /etc/supervisord.conf ;;
	help) cat << EOM
The image's entry point script will populate the following -parameters from linked
containers and Docker environment variables:
EOM
	echo -e "\ncassandra\t:" `add_cassandra_options $*` "\ndatanode\t:" `add_datanode_options $*` "\nnodemanager\t:" `add_nodemanager_options $*`
	echo -e "\n( Cassandra seed, HDFS NameNode and YARN ResourceManager countainers need to be linked under the aliases "seed", "namenode" and "resourcemanager" for this to happen. )\n"
	ruby /root/configure.rb $* ;;
	*) ruby /root/configure.rb $*
esac

