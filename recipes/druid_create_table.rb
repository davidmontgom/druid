data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")
datacenter = node.name.split('-')[0]
server_type = node.name.split('-')[1]
location = node.name.split('-')[2]

mysql_host = db[node.chef_environment][location]['druid']['mysql_host']
mysql_username = db[node.chef_environment][location]['druid']['mysql_username']
mysql_password = db[node.chef_environment][location]['druid']['mysql_password']
mysql_database = db[node.chef_environment][location]['druid']['mysql_database']

bash "install_druid_table" do
  user "root"
  cwd "var"
  code <<-EOH
    echo 'CREATE SCHEMA IF NOT EXISTS #{mysql_database};' | mysql -u root -p#{mysql_password}
    echo 'ALTER DATABASE #{mysql_database} charset=utf8;' | mysql -u root -p#{mysql_password}
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '#{mysql_password}';" | mysql -u root -p#{mysql_password}
    
    touch #{Chef::Config[:file_cache_path]}/druid_createtable.lock
  EOH
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/druid_createtable.lock")}
end


#echo 'CREATE SCHEMA IF NOT EXISTS druid;' | mysql -u root -pFeed312!
#echo "GRANT ALL ON druid.* TO 'druid'@'0.0.0.0' IDENTIFIED BY 'druid';" | mysql -u root -pFeed312!

#GRANT ALL PRIVILEGES ON *.* TO root@222.127.178.107  IDENTIFIED BY 'Feed312!' WITH GRANT OPTION;

#echo """GRANT ALL PRIVILEGES ON *.* TO root@222.127.178.107  IDENTIFIED BY 'Feed312!' WITH GRANT OPTION;""" % (ip_address,mysql_password)



#echo """GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Feed312!';""" | mysql -u root -pFeed312!
#echo "FLUSH PRIVILEGES;" | mysql -u root -pFeed312!