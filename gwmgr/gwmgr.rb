#!/usr/bin/env ruby
require 'bundler'
Bundler.require
Thread.abort_on_exception = true

DOMAIN='flokku.dev'

etcd = Etcd.client
router_key = "/apps"


unless etcd.exist?(router_key)
  etcd.create(router_key, dir: true)
end

unless etcd.exist?('/deployers')
  etcd.create('/deployers', dir: true)
end

system "touch /etc/nginx/sites-enabled/flokku"
system "service nginx restart"

nginx_mgr = Thread.new do
  while true
    puts "Reconfiguring router...\n"
    File.open("/etc/nginx/sites-enabled/flokku", "w") do |file|
      etcd.get(router_key).children.each do |child|
        app_name = child.key[/#{router_key}\/(.*+)/,1]
        ip = child.value
        puts "Routing application #{app_name} to #{ip}\n"
        file.puts <<-CONFIG
upstream flokku_#{app_name} {
  server #{ip}:80;
}

server {
  server_name #{app_name}.#{DOMAIN};
  location / {
    proxy_pass http://flokku_#{app_name};

    proxy_set_header Host $host;
    proxy_set_header  X-Real-IP  $remote_addr;
  }
}
      CONFIG
      end
    end
    system "service nginx reload"

    etcd.watch(router_key, recursive: true)
  end
end

access_mgr = Thread.new do
  while true
    puts "Configuring access...\n"
    system "rm -f /home/git/.ssh/authorized_keys &>/dev/null"

    etcd.get('/deployers').children.each do |deployer|
      user = deployer.key[/\/deployers\/(.+)/,1]
      puts "Enabling access for #{user}\n"
      system <<-CMD
        echo "#{deployer.value}" | /home/git/receiver upload-key #{user} > /dev/null
      CMD
    end

    etcd.watch('/deployers', recursive: true)
  end
end

nginx_mgr.join
access_mgr.join
