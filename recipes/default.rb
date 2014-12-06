


version="0.6.146"



bash "install_druid" do
  user "root"
  cwd "/var"
  code <<-EOH
    wget http://static.druid.io/artifacts/releases/druid-services-#{version}-bin.tar.gz
    tar -zxvf druid-services-*-bin.tar.gz
    mv druid-services-#{version} druid
  EOH
  action :run
  not_if {File.exists?("/var/druid")}
end

=begin
sudo lsof -i :8081
sudo lsof -i :8082
sudo lsof -i :8083
sudo lsof -i :8084
sudo lsof -i :8088
sudo lsof -i :9092



sudo kill `sudo lsof -t -i:8081`
sudo kill `sudo lsof -t -i:8082`
sudo kill `sudo lsof -t -i:8083`
sudo kill `sudo lsof -t -i:8084`
sudo kill `sudo lsof -t -i:8088`
sudo kill `sudo lsof -t -i:9092`
=end