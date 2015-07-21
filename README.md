## Cassandra + DataNode + NodeManager

### Overview

This is a Docker image that extends `andlaz/hadoop-base` for Hadoop binaries and installs Cassandra 2.1.7 and it's dependencies. Furthermore it configures ( via an entry point script ) and starts ( supervisord ) `Cassandra`, `DataNode` and `NodeManager` ( 1 process of each ) 

#### Goals

The ability to run map/reduce jobs against data ( partially or fully ) in Cassandra with _data locality_. The reason for having these separate ( daemon ) processes run from the same container is to ensure they are co-located physically. 

#### Notes

 - TODO : Figure out a way to ensure separate containers with one deamon process each, are co-located on the same physical host? This probably isnt a docker concern..?
 - **This is not HA**. It does not even fully recover after a `docker restart`. HA will be in version 2 along with Consul ( & Registrator ) for service discovery and Puppet to replace/supplement the entry point script for configuration.

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
Usage:
  configure.rb cassandra --listen-address=LISTEN_ADDRESS --rpc-address=RPC_ADDRESS

Options:
  [--cluster-name=CLUSTER_NAME]            # Name of the Cassandra cluster to join
                                           # Default: prose.andlaz.io
  [--initial-token=INITIAL_TOKEN]          # Inital token of the node being started. Required if calculate tokens is not set!
  [--calculate-tokens=CALCULATE_TOKENS]    # If the initial token is not specified, we can calulate murmur3 tokens. Provide node "sequence" id in the form of "node_seq:total_nr_of_nodes" e.g. 1:2, 2:2 etc
  [--data-dirs=DATA_DIRS]                  # Comma separated list of Cassandra data directories
                                           # Default: /var/lib/cassandra/data
  [--commit-log-dir=COMMIT_LOG_DIR]        # Directory in to which commit logs will be written
                                           # Default: /var/lib/cassandra/commitlog
  --listen-address=LISTEN_ADDRESS          # Address or interface to bind to and tell other Cassandra nodes to connect to
  --rpc-address=RPC_ADDRESS                # The address or interface to bind the Thrift RPC service and native transport server to
  [--broadcast-address=BROADCAST_ADDRESS]  # Address to broadcast to other Cassandra nodes. Leaving this blank will set it to the same value as listen_address

Configure and start only cassandra
```

#### HDFS Data Node configuration


#### Yarn Node Manager configuration


### Example

#### Without docker-compose

Start a name node [README for andlaz/hadoop-hdfs-nn]()

    docker run --name namenode -d andlaz/hadoop-hdfs-nn

Start a secondary name node [README for andlaz/hadoop-hdfs-nn]() and link your primary name node under the alias `namenode`

    docker run --name namenode-secondary --link namenode -d andlaz/hadoop-hdfs-nn secondary

Start a resource manager [README for andlaz/hadoop-yarn-rm]()

    docker run --name resourcemanager -d andlaz/hadoop-yarn-rm

Start ( Cassandra + NodeManager + DataNode ) x 2; make sure to link your primary name node and the resource manager under the aliases `namenode` and `resourcemanager`

    docker run --link namenode --link resourcemanager \
    -d andlaz/hadoop-cassandra all \
      --cassandra-calculate-tokens 1:2 \
      
    
    docker run --link namenode --link resourcemanager \
    -d andlaz/hadoop-cassandra all --cassandra-calculate-tokens 2:2

#### With docker-compose

#### To run hdfs/yarn client commands..

see [README of andlaz/hadoop-base](http://github.com/andlaz/hadoop-base)

### See also

High level overview of this cluster and an in-depth HOW-TO are available at (..)