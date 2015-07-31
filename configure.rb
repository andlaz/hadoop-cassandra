require "thor"
require "erb"

class Configure < Thor
 
  # ...
  def self.exit_on_failure?
    true
  end 
  
  class << self
    def options(options={})
      
      options.each do |option_name, option_settings|
        option option_name, option_settings  
      end
  
    end
  end
  
  module ERBRenderer
    
    def render_from(template_path)
      ERB.new(File.read(template_path), 0, '<>').result binding
    end
    
  end
  
  class CassandraConfiguration
    include ERBRenderer
    attr_accessor :cluster_name,
      :initial_token,
      :data_dirs,
      :commit_log_dir,
      :saved_caches_dir,
      :listen_address,
      :rpc_address,
      :broadcast_address,
      :seeds,
      :dc,
      :rack

  end
  
  class HDFSDataNodeConfiguration
    include ERBRenderer
    
    attr_accessor :tmp_dir,
      :data_dir,
      :default_fs,
      :name_node,
      :name_node_port,
      :hdfs_replication_factor,
      :hdfs_block_size
    
  end
  
  class YARNNodeManagerConfiguration
    include ERBRenderer
    
    attr_accessor :host_resource_manager,
      :web_ui_host,
      :web_ui_port,
      :node_containers_heap_total
    
  end
  
  
  @@cassandra_options = {
    :cluster_name => {:default => "prose.andlaz.io", :desc => "Name of the Cassandra cluster to join"},
    :initial_token => {:desc => "Inital token of the node being started. Required if calculate tokens is not set!"},
    :calculate_tokens => {:desc => "If the initial token is not specified, we can calulate murmur3 tokens. Provide node \"sequence\" id in the form of \"node_seq:total_nr_of_nodes\" e.g. 1:2, 2:2 etc"},
    :data_dirs => {:default => "/var/lib/cassandra/data", :desc => "Comma separated list of Cassandra data directories"},
    :saved_caches_dir => { :default => "/var/lib/cassandra/saved_caches", :desc => "Directory to store caches on disk"},
    :commit_log_dir => {:default => "/var/lib/cassandra/commitlog", :desc => "Directory in to which commit logs will be written"},
    :listen_address => {:required => true, :desc => "Address or interface to bind to and tell other Cassandra nodes to connect to"},
    :rpc_address => {:required => true, :desc => "The address or interface to bind the Thrift RPC service and native transport server to"},
    :broadcast_address => {:desc => "Address to broadcast to other Cassandra nodes. Leaving this blank will set it to the same value as listen_address"},
    :seeds => {:required => true, :desc => "Seed node/s"},
    :dc => {:required => true, :desc => "Name of the Cassandra DC the node will join"},
    :rack => {:default => "rack1", :desc => "Name of the Rack in the Cassandra DC the node sits on"}
  }
  
  @@datanode_options = {
    :tmp_dir => { :default => "/var/lib/hdfs/tmp", :desc => "HDFS temp dir" },
    :data_dir => { :default => "/var/lib/hdfs/data", :desc => "HDFS Data dir" },
    :name_node => { :required => true, :desc => "Host of the HDFS NameNode" },
    :name_node_port => { :default => 8020, :desc => "HDFS NameNode RPC port"}
  }
  
  @@nodemanager_options = {
    :resource_manager => { :required => true, :desc => "Host of the YARN ResourceManager" },
    :node_containers_heap_total => { :required => true, :desc => "Total memory available on the node to launch containers" },
    :web_ui_host => { :required => true, :desc => "Node Manager web ui host" },
    :web_ui_port => { :default => 8042, :desc => "Node Manager web ui port"}
  }  
  
  options @@cassandra_options
  options @@datanode_options
  options @@nodemanager_options
  desc "all", "Configure all daemons"
  def all
        
    puts invoke :cassandra, nil, skim(options, @@cassandra_options.keys)
    invoke :datanode, nil, skim(options, @@datanode_options.keys)
    invoke :nodemanager, nil, skim(options, @@nodemanager_options.keys)
    
    
  end
  
  desc "cassandra", "Configure Cassandra"
  options @@cassandra_options
  def cassandra

    configuration = CassandraConfiguration.new
    
    configuration.cluster_name = options[:cluster_name]
    configuration.data_dirs = options[:data_dirs].split ','
    configuration.commit_log_dir = options[:commit_log_dir]
    configuration.saved_caches_dir = options[:saved_caches_dir]
    configuration.listen_address = options[:listen_address]
    configuration.rpc_address = options[:rpc_address]
    configuration.broadcast_address = options[:broadcast_address].nil? ? options[:listen_address] : options[:broadcast_address]
    configuration.seeds = options[:seeds]
    configuration.dc = options[:dc]
    configuration.rack = options[:rack]
    
    # check if we can get to an initial_token
    
    if options[:initial_token].nil? == false
      # we have a token
      configuration.initial_token = options[:initial_token]
    elsif options[:calculate_tokens].nil? == false
      raise "--calculate-tokens must be in the form of {node_seq}:{total_nr_of_nodes}" if (options[:calculate_tokens].match /^\d+:\d+$/).nil?
      
      # we need to calculate token
      nodes = ((options[:calculate_tokens].split ':')[1]).to_i
      id = ((options[:calculate_tokens].split ':')[0]).to_i
      
      configuration.initial_token = ((2**64 / nodes) * id-1) - 2**63
      
      
    else
      raise "Could not determine initial_token; either supply it via --initial-token or --calculate-tokens"
    end

    # write configuration file
    File.write '/etc/cassandra/conf/cassandra.yaml',
      configuration.render_from('/etc/cassandra/conf/cassandra.yaml.erb')
      
    File.write '/etc/cassandra/conf/cassandra-rackdc.properties',
      configuration.render_from('/etc/cassandra/conf/cassandra-rackdc.properties.erb')
      
    File.write '/etc/supervisor/conf.d/cassandra.conf',
      configuration.render_from('/etc/supervisor/conf.d/cassandra.conf.erb')
    
    `chown -R hadoop #{options[:commit_log_dir]}`
    `chown -R hadoop #{options[:saved_caches_dir]}`
    
    configuration.data_dirs.each do |data_dir| 
      
      `chown -R hadoop #{data_dir}`
    
    end
    
    `chown -R hadoop /var/log/cassandra`
     
  end
  
  options @@datanode_options
  desc "datanode", "Configure the HDFS Data Node"
  def datanode
    
    configuration = HDFSDataNodeConfiguration.new
    
    configuration.tmp_dir = options[:tmp_dir]
    configuration.data_dir = options[:data_dir]
    configuration.default_fs = "hdfs://#{options[:name_node]}:#{options[:name_node_port]}"
    configuration.name_node = options[:name_node]
    configuration.name_node_port = options[:name_node_port]
    File.write '/etc/hadoop/core-site.xml',
      configuration.render_from('/etc/hadoop/core-site.xml.erb')
      
    File.write '/etc/hadoop/hdfs-site.xml',
      configuration.render_from('/etc/hadoop/hdfs-site.xml.erb')
      
    File.write '/etc/supervisor/conf.d/datanode.conf',
      configuration.render_from('/etc/supervisor/conf.d/datanode.conf.erb')
    
    FileUtils::mkdir_p options[:tmp_dir] unless File.exists? options[:tmp_dir]
    FileUtils::mkdir_p options[:data_dir] unless File.exists? options[:data_dir]
    
    `chown -R hadoop #{options[:tmp_dir]}`
    `chown -R hadoop #{options[:data_dir]}`
    
  end
  
  options @@nodemanager_options
  desc "nodemanager", "Configure the YARN Node Manager"
  def nodemanager
    
    configuration = YARNNodeManagerConfiguration.new
    configuration.host_resource_manager = options[:resource_manager]
    configuration.node_containers_heap_total = options[:node_containers_heap_total]
    configuration.web_ui_host = options[:web_ui_host]
    configuration.web_ui_port = options[:web_ui_port]
    
    File.write '/etc/hadoop/yarn-site.xml',
      configuration.render_from('/etc/hadoop/yarn-site.xml.erb')

    File.write '/etc/supervisor/conf.d/nodemanager.conf',
      configuration.render_from('/etc/supervisor/conf.d/nodemanager.conf.erb')
    
  end
  

  protected
  def skim(options, keys)
    
    return options.inject({}) { |h, (k, v)| if (h != nil && (keys.include? k.to_sym)) then h[k.to_sym] = v end; h }
    
  end
  
end

Configure.start(ARGV)
