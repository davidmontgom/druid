server_type = node.name.split('-')[0]
slug = node.name.split('-')[1] 
datacenter = node.name.split('-')[2]
environment = node.name.split('-')[3]
location = node.name.split('-')[4]
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 

data_bag("meta_data_bag")
aws = data_bag_item("meta_data_bag", "aws")
domain = aws[node.chef_environment]["route53"]["domain"]
zone_id = aws[node.chef_environment]["route53"]["zone_id"]
AWS_ACCESS_KEY_ID = aws[node.chef_environment]['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = aws[node.chef_environment]['AWS_SECRET_ACCESS_KEY']



#http://stackoverflow.com/questions/4000713/tell-the-end-of-a-each-loop-in-ruby
druid = data_bag_item("meta_data_bag", "druid")
s3bucket = druid[node.chef_environment]['s3bucket']
s3basekey = druid[node.chef_environment]['s3basekey']
ruleTable = druid[node.chef_environment]['ruleTable']
realtime_list = druid[node.chef_environment]['realtime']




data_bag("server_data_bag")
zookeeper_server = data_bag_item("server_data_bag", "zookeeper")
if cluster_slug=="nocluster"
  subdomain = "zookeeper-#{slug}-#{datacenter}-#{environment}-#{location}"
else
  subdomain = "zookeeper-#{slug}-#{datacenter}-#{environment}-#{location}-#{cluster_slug}"
end
required_count = zookeeper_server[datacenter][environment][location][cluster_slug]['required_count']
full_domain = "#{subdomain}.#{domain}"



version = node[:druid][:version]

execute "restart_supervisorctl_realtime" do
  command "sudo supervisorctl restart realtime_server:"
  action :nothing
end


if node.chef_environment=='local'
  #http://druid.io/docs/0.6.143/Production-Cluster-Configuration.html
  broker_druid_port = '8084'
  coodrdinator_druid_port = '8085'
  historical_druid_port = '8081'
  overlord_druid_port = '8088'
  realtime_druid_port = '8083'
  service "supervisord"
  druid_nodes = ['broker','coordinator','historical','overlord','realtime']  
  zookeeper = 'localhost'
  ipaddress = 'localhost'
end


if node.chef_environment!='local'
  broker_druid_port = '8082'
  coodrdinator_druid_port = '8082'
  historical_druid_port = '8082'
  overlord_druid_port = '8082'
  realtime_druid_port = '8082'
  service "supervisord"
  ipaddress = node[:ipaddress]
  druid_nodes = ['realtime']  
  #zookeeper = 'localhost'
end

if server_type=='druidrealtime'
    if File.exists?("/var/shard_index")
      partitionNum = File.read("/var/shard_index.txt")
      partitionNum = partitionNum.to_i - 1
    end
    if node.chef_environment=='local'
      partitionNum = 0
    end
    
    template "/var/realtime.spec" do
      path "/var/realtime.spec"
      source "realtime.spec.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy {{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :version => version, :environment => node.chef_environment,
        :AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :realtime_list => realtime_list,
        :partitionNum => partitionNum
      }}
      
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_realtime]"
    end
end



if node.chef_environment=='local'
  
    partitionNum = 0

    template "/var/realtime.spec" do
      path "/var/realtime.spec"
      source "realtime.spec.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy {{
        :zookeeper => "localhost:2181", :version => version, :environment => node.chef_environment,
        :AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :realtime_hash => realtime_hash,
        :partitionNum => partitionNum
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_realtime]"
    end
end    