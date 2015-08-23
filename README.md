## Cassandra + DataNode + NodeManager

### Overview

This is a Docker image that extends `andlaz/hadoop-base` for Hadoop binaries and installs Cassandra 2.1.7 and it's dependencies. Furthermore it configures ( via an entry point script ) and starts ( supervisord ) `Cassandra`, `DataNode` and `NodeManager` ( 1 process of each ) 

#### Goals

The ability to run map/reduce jobs against data ( partially or fully ) in Cassandra with _data locality_. The reason for having these separate ( daemon ) processes run from the same container is to ensure they are co-located physically. 

#### Notes

### Usage

#### Linked containers

 - An HDFS NameNode ( `namenode` : `andlaz/hadoop-hdfs-namenode` )
 - A YARN ResourceManager ( `resourcemanager` : `andlaz/hadoop-yarn-rm` )

#### Paths of interest

The following directories should be mounted from the Docker host, so data ( other than logs ) doesn't end up in the container

 - /var/lib/cassandra/data
 - /var/lib/cassandra/commitlog
 - /var/lib/hdfs/data
 - /var/lib/hdfs/tmp

If you are looking to have a performant setup, these should each be dedicated disks per container

Some configuration files of these daemons/processes are altered by the entry point `configure.rb` Below you may find it's detailed usage

    docker run andlaz/hadoop-cassandra (all|cassandra|datanode|nodemanager) \
    	--{paramter_name}={parameter_value}

#### Cassandra configuration

```
 docker run -ti --rm andlaz/hadoop-cassandra help cassandra
The image's entry point script will populate the following -parameters from linked
containers and Docker environment variables:

cassandra	: --seeds 172.17.0.43 --listen-address 0e018cb4bc3c --rpc-address 0e018cb4bc3c 
datanode	: 
nodemanager	: --web-ui-host 0e018cb4bc3c

( Cassandra seed, HDFS NameNode and YARN ResourceManager countainers need to be linked under the aliases seed, namenode and resourcemanager for this to happen. )

Usage:
  configure.rb cassandra --dc=DC --listen-address=LISTEN_ADDRESS --rpc-address=RPC_ADDRESS --seeds=SEEDS

Options:
  [--cluster-name=CLUSTER_NAME]            # Name of the Cassandra cluster to join
                                           # Default: prose.andlaz.io
  [--initial-token=INITIAL_TOKEN]          # Inital token of the node being started. Required if calculate tokens is not set!
  [--calculate-tokens=CALCULATE_TOKENS]    # If the initial token is not specified, we can calulate murmur3 tokens. Provide node "sequence" id in the form of "node_seq:total_nr_of_nodes" e.g. 1:2, 2:2 etc
  [--data-dirs=DATA_DIRS]                  # Comma separated list of Cassandra data directories
                                           # Default: /var/lib/cassandra/data
  [--saved-caches-dir=SAVED_CACHES_DIR]    # Directory to store caches on disk
                                           # Default: /var/lib/cassandra/saved_caches
  [--commit-log-dir=COMMIT_LOG_DIR]        # Directory in to which commit logs will be written
                                           # Default: /var/lib/cassandra/commitlog
  --listen-address=LISTEN_ADDRESS          # Address or interface to bind to and tell other Cassandra nodes to connect to
  --rpc-address=RPC_ADDRESS                # The address or interface to bind the Thrift RPC service and native transport server to
  [--broadcast-address=BROADCAST_ADDRESS]  # Address to broadcast to other Cassandra nodes. Leaving this blank will set it to the same value as listen_address
  --seeds=SEEDS                            # Seed node/s
  --dc=DC                                  # Name of the Cassandra DC the node will join
  [--rack=RACK]                            # Name of the Rack in the Cassandra DC the node sits on
                                           # Default: rack1

Configure Cassandra
```

#### HDFS Data Node configuration

```
docker run -ti --rm andlaz/hadoop-cassandra help datanode
The image's entry point script will populate the following -parameters from linked
containers and Docker environment variables:

cassandra	: --seeds 172.17.0.44 --listen-address 7068259025ce --rpc-address 7068259025ce 
datanode	: 
nodemanager	: --web-ui-host 7068259025ce

( Cassandra seed, HDFS NameNode and YARN ResourceManager countainers need to be linked under the aliases seed, namenode and resourcemanager for this to happen. )

Usage:
  configure.rb datanode --name-node=NAME_NODE

Options:
  [--tmp-dir=TMP_DIR]                # HDFS temp dir
                                     # Default: /var/lib/hdfs/tmp
  [--data-dir=DATA_DIR]              # HDFS Data dir
                                     # Default: /var/lib/hdfs/data
  --name-node=NAME_NODE              # Host of the HDFS NameNode
  [--name-node-port=NAME_NODE_PORT]  # HDFS NameNode RPC port
                                     # Default: 8020

Configure the HDFS Data Node
```

#### Yarn Node Manager configuration

```
docker run -ti --rm andlaz/hadoop-cassandra help nodemanager
The image's entry point script will populate the following -parameters from linked
containers and Docker environment variables:

cassandra	: --seeds 172.17.0.45 --listen-address 84cd3a39a5e2 --rpc-address 84cd3a39a5e2 
datanode	: 
nodemanager	: --web-ui-host 84cd3a39a5e2

( Cassandra seed, HDFS NameNode and YARN ResourceManager countainers need to be linked under the aliases seed, namenode and resourcemanager for this to happen. )

Usage:
  configure.rb nodemanager --node-containers-heap-total=NODE_CONTAINERS_HEAP_TOTAL --resource-manager=RESOURCE_MANAGER --web-ui-host=WEB_UI_HOST

Options:
  --resource-manager=RESOURCE_MANAGER                      # Host of the YARN ResourceManager
  --node-containers-heap-total=NODE_CONTAINERS_HEAP_TOTAL  # Total memory available on the node to launch containers
  --web-ui-host=WEB_UI_HOST                                # Node Manager web ui host
  [--web-ui-port=WEB_UI_PORT]                              # Node Manager web ui port
                                                           # Default: 8042

Configure the YARN Node Manager
```

#### Examples

Note that we are not mounting any paths on the docker host to these containers as we start them. This means once the container goes,
your data goes. That makes the set-ups below suitable for playing around only.

##### Start a Cassandra cluster

This one is the simplest - it has no links to outside containers

##### Start an HDFS cluster

##### Start a YARN cluster

##### Start a YARN + HDFS + Cassandra cluster

Format the HDFS data directory

    docker run \
      -ti \
      --rm \
      andlaz/hadoop-hdfs-namenode namenode --format

Start a name node [README for andlaz/hadoop-hdfs-namenode](), expose HDFS web ui on the docker host

    docker run \
      --publish 0.0.0.0:50070:50070 \
      --name nn1 \
      -tid \
      andlaz/hadoop-hdfs-namenode namenode

Start a secondary name node [README for andlaz/hadoop-hdfs-namenode]() and link your primary name node under the alias `namenode`

    docker run \
      --name nn2 \
      --link nn1:namenode \
      -tid \
      andlaz/hadoop-hdfs-namenode namenodesecondary

Start a resource manager [README for andlaz/hadoop-yarn-resourcemanager]()

    docker run \
    --name rm \
    -tid \
    andlaz/hadoop-yarn-resourcemanager resourcemanager

Start ( Cassandra + NodeManager + DataNode ) x 2; make sure to link your primary name node and the resource manager under the aliases `namenode` and `resourcemanager`

    docker run --name worker-1 \
    --link nn1:namenode \
    --link rm:resourcemanager \
    -d \
    andlaz/hadoop-cassandra all \
      --cassandra-calculate-tokens 1:2
      --dc cass-1
    
    docker run --name worker-2 \
    --link nn1:namenode \
    --link rm:resourcemanager \
    --link worker-2:seed \
    -d \
    andlaz/hadoop-cassandra all \
      --cassandra-calculate-tokens 2:2
      --dc cass-1

#### To run hdfs/yarn client commands..

see [README of andlaz/hadoop-base](http://github.com/andlaz/hadoop-base)

### See also

