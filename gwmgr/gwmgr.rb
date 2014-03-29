#!/usr/bin/env ruby
require 'bundler'
Bundler.require

DOMAIN='flokku.dev'

etcd = Etcd.client
router_key = "/router"


unless etcd.exist?(router_key)
  etcd.create(router_key, dir: true)
end

File.open("/etc/nginx/sites-enabled/flokku", "w") do |file|
end
system "service nginx restart"

while true
  File.open("/etc/nginx/sites-enabled/flokku", "w") do |file|
    etcd.get(router_key).children.each do |child|
      app_name = child.key[/#{router_key}\/(.*+)/,1]
      ip = child.value

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
