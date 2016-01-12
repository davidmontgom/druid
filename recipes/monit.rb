datacenter = node.name.split('-')[0]
environment = node.name.split('-')[1]
location = node.name.split('-')[2]
server_type = node.name.split('-')[3]
slug = node.name.split('-')[4] 
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 

if server_type=='druidcoordinator'
  role = 'coordinator'
end
if server_type=='druidbroker'
  role = 'broker'
end
if server_type=='druidrealtime'
  role = 'realtime'
end
if server_type=='druidoverlord'
  role = 'overlord'
end
if server_type=='druidhistorical'
  role = 'historical'
end


service "monit"
version = node[:druid][:version]
template "/etc/monit/conf.d/#{server_type}.conf" do
  path "/etc/monit/conf.d/#{server_type}.conf"
  source "monit.druid.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  variables :role => role, :version => version
  notifies :restart, resources(:service => "monit")
end