# MIT License
#
# Copyright (c) 2022-2022 Carlo Corradini
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

require 'ipaddr'

BOX = "generic/alpine316"
VM_RAM = 1024
VM_CPU = 1
NODES = [
  {
    :hostname => "controller",
    :ip => "10.0.0.10"
  },
  {
    :hostname => "worker",
    :ip => "10.0.0.100"
  }
]

$script = <<-SCRIPT
#!/usr/bin/env sh

# Fail on error
set -o errexit
# Disable wildcard character expansion
set -o noglob

#
# PACKAGES
#
apk add --update --no-cache \
  coreutils \
  ethtool \
  inotify-tools \
  iproute2 \
  jq \
  ncurses \
  procps \
  sudo \
  sysbench \
  util-linux \
  yq
SCRIPT

Vagrant.configure("2") do |config|
  # Box
  config.vm.box = BOX

  # Provider
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = VM_RAM
    vb.cpus = VM_CPU
  end

  # Synced folder
  config.vm.synced_folder "./", "/vagrant"

  # SSH
  config.ssh.extra_args = ["-t", "cd /vagrant; bash --login"]

  # Nodes
  NODES.each do |node_config|
    config.vm.define node_config[:hostname] do |config|
      # Network
      config.vm.hostname = "#{node_config[:hostname]}.recluster.local"
      config.vm.network :private_network, ip: IPAddr.new(node_config[:ip]).to_s, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
      config.vm.provision 'hosts' do |hosts|
        hosts.autoconfigure = true
        hosts.sync_hosts = true
        hosts.add_localhost_hostnames = false
      end

      # Provision
      config.vm.provision "shell", inline: $script
    end
  end
end
