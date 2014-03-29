#!/usr/bin/env ruby
require 'bundler'
require 'open3'
Bundler.require

etcd = Etcd.client

def set_router_public_key(response)
  cmd = "sshcommand acl-add dokku flokku"
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.puts response.value
    stdin.close
    stdout.readlines.each do |line|
      puts line
    end
  end
end

if etcd.exists?(rpk_key = '/router_public_key')
  set_router_public_key etcd.get(rpk_key)
end

while true
  set_router_public_key etcd.watch(rpk_key)
end
