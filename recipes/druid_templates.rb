
datacenter = node.name.split('-')[0]
server_type = node.name.split('-')[1]
location = node.name.split('-')[2]


data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")
AWS_ACCESS_KEY_ID = db[node.chef_environment]['aws']['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = db[node.chef_environment]['aws']['AWS_SECRET_ACCESS_KEY']

druid = data_bag_item("my_data_bag", "druid")
druid_master = druid[node.chef_environment][datacenter][location]['druid_master']
s3bucket = druid[node.chef_environment][datacenter][location]['s3bucket']
s3basekey = druid[node.chef_environment][datacenter][location]['s3basekey']
ruleTable = druid[node.chef_environment][datacenter][location]['ruleTable']
mysql_host = druid[node.chef_environment][datacenter][location]['mysql_host']
mysql_username = druid[node.chef_environment][datacenter][location]['mysql_username']
mysql_password = druid[node.chef_environment][datacenter][location]['mysql_password']
mysql_database = druid[node.chef_environment][datacenter][location]['mysql_database']
domain = db[node.chef_environment]['domain']


version = node[:druid][:version]

execute "restart_supervisorctl_overlord" do
  command "sudo supervisorctl restart overlord_server:"
  action :nothing
end
execute "restart_supervisorctl_broker" do
  command "sudo supervisorctl restart broker_server:"
  action :nothing
end
execute "restart_supervisorctl_coordinator" do
  command "sudo supervisorctl restart coordinator_server:"
  action :nothing
end
execute "restart_supervisorctl_realtime" do
  command "sudo supervisorctl restart realtime_server:"
  action :nothing
end
execute "restart_supervisorctl_historical" do
  command "sudo supervisorctl restart historical_server:"
  action :nothing
end

=begin
if File.exists?("#{Chef::Config[:file_cache_path]}/zookeeper_hosts")
    zookeeper = File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts")
end
=end


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
  druid_nodes = ['broker','coordinator','historical','overlord','realtime']  
  #zookeeper = 'localhost'
end

                 
if server_type=='druidcoordinator' or node.chef_environment=='local'
  template "/var/druid-#{version}/config/coordinator/runtime.properties" do
      path "/var/druid-#{version}/config/coordinator/runtime.properties"
      source "coordinator.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      #variables lazy {{:zookeeper => File.read("/var/zookeeper_hosts")}}
      variables lazy{{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :druid_port => coodrdinator_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :ipaddress => ipaddress
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_coordinator]"
    end
    
    template "/etc/supervisor/conf.d/supervisord.coordinator.conf" do
      path "/etc/supervisor/conf.d/supervisord.coordinator.conf"
      source "supervisord.coordinator.conf.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :interval => "240",:version => version
      })
      notifies :run, "execute[restart_supervisorctl_coordinator]"
    end
end

if server_type=='druidbroker' or node.chef_environment=='local'
  template "/var/druid-#{version}/config/broker/runtime.properties" do
      path "/var/druid-#{version}/config/broker/runtime.properties"
      source "broker.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy{{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :druid_port => broker_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :ipaddress => ipaddress
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_broker]"
    end
    
    template "/etc/supervisor/conf.d/supervisord.broker.conf" do
      path "/etc/supervisor/conf.d/supervisord.broker.conf"
      source "supervisord.broker.conf.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :interval => "240",:version => version
      })
      notifies :run, "execute[restart_supervisorctl_broker]"
    end
end

if server_type=='druidhistorical' or node.chef_environment=='local'
  template "/var/druid-#{version}/config/historical/runtime.properties" do
      path "/var/druid-#{version}/config/historical/runtime.properties"
      source "historical.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy {{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :druid_port => historical_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :ipaddress => ipaddress,:AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_historical]"
    end
    
    template "/etc/supervisor/conf.d/supervisord.historical.conf" do
      path "/etc/supervisor/conf.d/supervisord.historical.conf"
      source "supervisord.historical.conf.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :interval => "240",:version => version
      })
      notifies :run, "execute[restart_supervisorctl_historical]"
    end
end

if server_type=='druidoverlord' or node.chef_environment=='local'
  template "/var/druid-#{version}/config/overlord/runtime.properties" do
      path "/var/druid-#{version}/config/overlord/runtime.properties"
      source "overlord.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy{{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :druid_port => overlord_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :ipaddress => ipaddress,:AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_overlord]"
    end
    
    template "/etc/supervisor/conf.d/supervisord.overlord.conf" do
      path "/etc/supervisor/conf.d/supervisord.overlord.conf"
      source "supervisord.overlord.conf.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :interval => "240",:version => version
      })
      notifies :run, "execute[restart_supervisorctl_overlord]"
    end
end

if server_type=='druidrealtime' or node.chef_environment=='local'

  template "/var/druid-#{version}/config/realtime/runtime.properties" do
      path "/var/druid-#{version}/config/realtime/runtime.properties"
      source "realtime.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables lazy{{
        :zookeeper => File.read("#{Chef::Config[:file_cache_path]}/zookeeper_hosts"), :druid_port => realtime_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :ipaddress => ipaddress,:AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      }}
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_realtime]"
    end
     
    template "/etc/supervisor/conf.d/supervisord.realtime.conf" do
      path "/etc/supervisor/conf.d/supervisord.realtime.conf"
      source "supervisord.realtime.conf.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :interval => "240",:version => version
      })
      notifies :run, "execute[restart_supervisorctl_realtime]"
    end
end





if node.chef_environment=='local'
  
    partitionNum = 0

    template "/var/druid-#{version}/config/overlord/runtime.properties" do
      path "/var/druid-#{version}/config/overlord/runtime.properties"
      source "overlord.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables({
        :zookeeper => zookeeper, :druid_port => overlord_druid_port, :version => version,:ipaddress => ipaddress,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      })
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_overlord]"
      
      
    end
    
    template "/var/druid-#{version}/config/broker/runtime.properties" do
      path "/var/druid-#{version}/config/broker/runtime.properties"
      source "broker.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables({
        :zookeeper => zookeeper, :druid_port => broker_druid_port, :version => version,:ipaddress => ipaddress
      })
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_broker]"
    end
    
    template "/var/druid-#{version}/config/historical/runtime.properties" do
      path "/var/druid-#{version}/config/historical/runtime.properties"
      source "historical.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables({
        :zookeeper => zookeeper, :druid_port => historical_druid_port, :version => version,:ipaddress => ipaddress,
        :AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      })
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_historical]"
    end
=begin    
    template "/var/druid/config/coordinator/runtime.properties" do
      path "/var/druid/config/coordinator/runtime.properties"
      source "coordinator.runtime.properties.erb"
      owner "root"
      group "root"
      mode "0644"
      variables({
        :zookeeper => zookeeper, :druid_port => coodrdinator_druid_port, :version => version,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database
      })
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_coordinator]"
    end
=end
    
    template "/var/druid-#{version}/config/realtime/runtime.properties" do
      path "/var/druid-#{version}/config/realtime/runtime.properties"
      source "realtime.runtime.properties.#{version}.erb"
      owner "root"
      group "root"
      mode "0644"
      variables({
        :zookeeper => zookeeper, :druid_port => realtime_druid_port, :version => version,
        :AWS_ACCESS_KEY_ID => AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY => AWS_SECRET_ACCESS_KEY,:ipaddress => ipaddress,
        :mysql_username => mysql_username, :mysql_password => mysql_password, :mysql_host => mysql_host, :mysql_database => mysql_database,
        :s3bucket => s3bucket, :s3basekey => s3basekey
      })
      #notifies :restart, resources(:service => "supervisord")
      notifies :run, "execute[restart_supervisorctl_realtime]"
    end
end    
   



















