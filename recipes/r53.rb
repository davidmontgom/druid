data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")

datacenter = node.name.split('-')[0]
server_type = node.name.split('-')[1]
location = node.name.split('-')[2]

easy_install_package "boto" do
  action :install
end



  
AWS_ACCESS_KEY_ID = db[node.chef_environment]['aws']['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = db[node.chef_environment]['aws']['AWS_SECRET_ACCESS_KEY']
zone_id = db[node.chef_environment]['aws']['route53']['zone_id']
domain = db[node.chef_environment]['aws']['route53']['domain']

script "zookeeper_myid" do
  interpreter "python"
  user "root"
  cwd "/root"
code <<-PYCODE
import json
import os
from boto.route53.connection import Route53Connection
from boto.route53.record import ResourceRecordSets
from boto.route53.record import Record
import hashlib
conn = Route53Connection('#{AWS_ACCESS_KEY_ID}', '#{AWS_SECRET_ACCESS_KEY}')
records = conn.get_all_rrsets('#{zone_id}')
host_list = {}
prefix={}
root = None
for record in records:
  if record.name.find('zk')>=0 and record.name.find('#{location}')>=0 and record.name.find('#{node.chef_environment}')>=0:
    if record.resource_records[0]!='#{node[:ipaddress]}':
      host_list[record.name[:-1]+":2181"]=record.resource_records[0]
      p = record.name.split('.')[0]
      prefix[p]=1
      root = record.name[:-1]
with open('#{Chef::Config[:file_cache_path]}/zookeeper_hosts.json', 'w') as fp:
  json.dump(host_list, fp)
fnl=["#{Chef::Config[:file_cache_path]}/zookeeper_hosts.json"]
fh = [(fname, hashlib.md5(open("#{Chef::Config[:file_cache_path]}/zookeeper_hosts.json", 'rb').read()).hexdigest()) for fname in fnl][0][1]
hash_file = '#{Chef::Config[:file_cache_path]}/fh_%s' % fh
if not os.path.isfile(hash_file):
  try:
    os.system('rm #{Chef::Config[:file_cache_path]}/fh_*')
  except:
    pass
  os.system('touch %s' % hash_file)
  f = open('/var/chef/cache/zookeeper_hosts','w')
  tmp = ','.join(host_list.keys())
  f.write(tmp)
  f.close()
PYCODE
end
  
  
  
  
  







