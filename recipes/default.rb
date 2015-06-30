


version="0.7.3"
bash "install_druid" do
  user "root"
  cwd "/var"
  code <<-EOH
    wget http://static.druid.io/artifacts/releases/druid-#{version}-bin.tar.gz
    tar -zxvf druid-#{version}-bin.tar.gz
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