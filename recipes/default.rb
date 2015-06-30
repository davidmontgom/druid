

#http://static.druid.io/artifacts/releases/druid-0.7.3-bin.tar.gz
version="0.7.3"
#version="0.7.0"


bash "install_druid" do
  user "root"
  cwd "/var"
  code <<-EOH
    wget http://static.druid.io/artifacts/releases/druid-services-#{version}-bin.tar.gz
    #tar -zxvf druid-services-*-bin.tar.gz
    tar -zxvf druid-services-#{version}-bin.tar.gz
    #mv druid-services-#{version} druid
  EOH
  action :run
  not_if {File.exists?("/var/druid-#{version}")}
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