#!/usr/bin/env ruby
require 'bundler'
require 'open3'
Bundler.require
Thread.abort_on_exception = true

MYIP = `ifconfig | grep 192.168 | awk '{{print $2}}' | cut -d ':' -f 2`.chomp
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

def monitor_application(application)
  if application.value == MYIP
    $applications[name = application.key] ||= Thread.new do
      puts "Application #{name} assigned to #{MYIP}"
      while true
        ip = Etcd.client.watch(name)
        unless ip && ip.value == MYIP
          puts "Removing application...\n"
          $applications.delete(name)
          system p("dokku delete #{name[/\/apps\/(.+)/, 1]}")
          break
        end
      end
    end
  end
end

if etcd.exists?(rpk_key = '/router_public_key')
  set_router_public_key etcd.get(rpk_key)
end

$applications = {}

etcd.get('/apps', recursive: true).children.each do |application|
  monitor_application(application)
end

Thread.new do
  while true
    etcd.watch('/apps', recursive: true)
    etcd.get('/apps', recursive: true).children.each do |application|
      monitor_application(application)
    end
    sleep 1
  end
end

Thread.new do
  while true
    set_router_public_key etcd.watch(rpk_key)
  end
end.join
