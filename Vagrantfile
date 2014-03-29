Vagrant.configure("2") do |config|
  DOMAIN = "flokku.dev"

  config.vm.define "dokku-gw" do |dokku|
    dokku.vm.box = "ubuntu-docker"
    dokku.vm.network "private_network", ip: "192.168.50.2"
    dokku.vm.provision "shell", inline: <<-SCRIPT
      apt-get update
      export DEBIAN_FRONTEND=noninteractive
      apt-get install -y nginx git python-software-properties ruby1.9.1
      gem install bundler

      cd /tmp
      wget -O etcd.tar.gz https://github.com/coreos/etcd/releases/download/v0.3.0/etcd-v0.3.0-linux-amd64.tar.gz
      tar xf etcd.tar.gz
      cd etcd-*
      cp etcd etcdctl /usr/local/bin/
      cd /root

      mkdir -p /var/lib/etcd
      ln -sf /vagrant/shared/etcd.conf /etc/init/etcd.conf
      ln -sf /vagrant/shared/gwmgr.conf /etc/init/gwmgr.conf
      initctl reload-configuration

      start etcd
      start gwmgr

      wget -O /usr/local/bin/gitreceive https://raw.github.com/progrium/gitreceive/master/gitreceive
      chmod +x /usr/local/bin/gitreceive
      gitreceive init
      ssh-keygen -t rsa -q -f /home/git/.ssh/id_rsa -N ''
      chown git /home/git/.ssh/id_rsa*
      etcdctl set /router_public_key "$(cat /home/git/.ssh/id_rsa.pub)"
      ln -sf /vagrant/gwmgr/receiver /home/git/receiver
    SCRIPT
  end

  [0,1].each do |i|
    config.vm.define "dokku-#{i}" do |dokku|
      dokku.vm.box = "ubuntu-docker"
      dokku.vm.network "private_network", ip: "192.168.50.#{i+3}"
      dokku.vm.provision "shell", inline: <<-SCRIPT
        wget -qO- https://raw.github.com/progrium/dokku/master/bootstrap.sh | sudo bash && \
        echo "#{DOMAIN}" > /home/dokku/VHOST

        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ruby1.9.1
        gem install bundler

        cd /tmp
        wget -O etcd.tar.gz https://github.com/coreos/etcd/releases/download/v0.3.0/etcd-v0.3.0-linux-amd64.tar.gz
        tar xf etcd.tar.gz
        cd etcd-*
        cp etcd etcdctl /usr/local/bin/
        cd /root

        mkdir -p /var/lib/etcd
        ln -sf /vagrant/shared/etcd_node.conf /etc/init/etcd.conf
        ln -sf /vagrant/shared/nodemgr.conf /etc/init/nodemgr.conf
        initctl reload-configuration

        start etcd
        start nodemgr
      SCRIPT
    end
  end
end
