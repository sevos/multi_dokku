#!/usr/bin/env ruby
require 'bundler'
Bundler.require

DOMAIN='flokku.dev'

etcd = Etcd.client
router_key = "/apps"


unless etcd.exist?(router_key)
  etcd.create(router_key, dir: true)
end

system "touch /etc/nginx/sites-enabled/flokku"
system "service nginx restart"

while true
  puts "Reconfiguring router..."
  File.open("/etc/nginx/sites-enabled/flokku", "w") do |file|
    etcd.get(router_key).children.each do |child|
      app_name = child.key[/#{router_key}\/(.*+)/,1]
      ip = child.value
      puts "Routing application #{app_name} to #{ip}"
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
