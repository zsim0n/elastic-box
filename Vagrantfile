# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "zsim0n/awesome-trusty"
  config.vm.hostname = "elastic.dev"
  config.vm.network "private_network", ip: "172.16.16.29"
  config.vm.network :forwarded_port, guest: 5601, host: 5601
  config.vm.network :forwarded_port, guest: 9200, host: 9200
  config.vm.network :forwarded_port, guest: 9292, host: 9292
  config.vm.network :forwarded_port, guest: 9300, host: 9300

#  config.vm.synced_folder '.', '/vagrant', type: 'nfs',  mount_options: ['rw', 'vers=3', 'tcp', 'fsc' ,'actimeo=2'],:bsd__nfs_options => ["maproot=0:0"]
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--cpus", 4]
  end

  config.vm.provision :shell, :path => 'shell/bootstrap.sh'

  config.ssh.forward_agent = true
end
