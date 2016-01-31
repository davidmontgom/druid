datacenter = node.name.split('-')[0]
environment = node.name.split('-')[1]
location = node.name.split('-')[2]
server_type = node.name.split('-')[3]
slug = node.name.split('-')[4] 
cluster_slug = File.read("/var/cluster_slug.txt")
cluster_slug = cluster_slug.gsub(/\n/, "") 
cluster_slug_druid = "druid"
data_bag("meta_data_bag")
git = data_bag_item("meta_data_bag", "git")
aws = data_bag_item("meta_data_bag", "aws")
domain = aws[node.chef_environment]["route53"]["domain"]

data_bag("server_data_bag")
mysql_server = data_bag_item("server_data_bag", server_type)
mysql_password = mysql_server[datacenter][environment][location][cluster_slug_druid]['meta']['password']
mysql_username = mysql_server[datacenter][environment][location][cluster_slug_druid]['meta']['username']
mysql_database = "druid"
mysql_host = "primary-druid-mysql-#{datacenter}-#{environment}-#{location}-#{slug}.#{domain}"

=begin

echo "CREATE USER 'fabric_store'@'%' IDENTIFIED BY 'Test101';" | mysql -u root -p#{password}
    echo "GRANT ALTER, CREATE, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, SELECT, UPDATE ON mysql_fabric.* TO 'fabric_store'@'%';" | mysql -u root -p#{password}
    echo "FLUSH PRIVILEGES;" | mysql -u root -p#{password}

CREATE DATABASE druid DEFAULT CHARACTER SET utf8;   CHARACTER SET utf8
CREATE USER 'druid'@'%' IDENTIFIED BY 'diurd';
GRANT ALL ON druid.* TO 'druid'@'%' IDENTIFIED BY 'diurd';
FLUSH PRIVILEGES;



GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'Test101';
CREATE USER 'druid'@'%' IDENTIFIED BY 'diurd';

new
http://dba.stackexchange.com/questions/30768/access-denied-for-user-root
grant all privileges on *.* to 'root'@'%' with grant option;
CREATE DATABASE druid DEFAULT CHARACTER SET utf8;
CREATE USER 'druid'@'%' IDENTIFIED BY 'diurd';
FLUSH PRIVILEGES;

=end

bash "install_druid_table" do
  user "root"
  cwd "var"
  code <<-EOH
    echo 'CREATE SCHEMA IF NOT EXISTS #{mysql_database};' | mysql -u root -p#{mysql_password}
    echo 'ALTER DATABASE #{mysql_database} charset=utf8;' | mysql -u root -p#{mysql_password}
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