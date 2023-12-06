Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |vb|
      vb.memory = 256
      vb.linked_clone = true
  end

  # method to create the machines
  def create_machine(config, name, box, hostname, provision, ip_address)
      config.vm.define name do |node|
          node.vm.box = box
          node.vm.hostname = hostname
          node.vm.network :private_network, type: "static", ip: ip_address
          node.vm.provision "shell", path: provision
          node.vm.provision "shell", inline: "cp /vagrant/config/resolv.conf /etc/", run: "always"
      end
  end

  # creation of the machines
  create_machine(config, "tierra", "debian/bullseye64", "tierra.sistema.sol", "provision.sh", "192.168.57.103")
  create_machine(config, "venus", "debian/bullseye64", "venus.sistema.sol", "provision.sh", "192.168.57.102")

end