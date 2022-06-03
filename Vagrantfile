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

BOX = "generic/alpine316"
VM_RAM = 1024
VM_CPU = 1
NODES = [
  {
    :hostname => "controller",
    :ip => "10.0.0.10"
  },
  {
    :hostname => "worker-0",
    :ip => "10.0.0.100"
  },
  {
    :hostname => "worker-1",
    :ip => "10.0.0.101"
  }
]

$script = <<-SCRIPT
# Packages
apk add --update --no-cache \
  coreutils \
  ethtool \
  iproute2 \
  jq \
  ncurses \
  procps \
  sudo \
  sysbench \
  util-linux \
  yq
SCRIPT

$controller = <<-SCRIPT
# Packages
apk add --update --no-cache \
  bash \
  docker \
  docker-compose \
  nodejs \
  npm

# === Docker
# User
addgroup vagrant docker
# Service
rc-update add docker boot
service docker start

# Docker reCluster server
/vagrant/server/scripts/dockerize.sh

# npm dependencies
npm --prefix /vagrant/server install --ignore-scripts
SCRIPT

Vagrant.configure("2") do |config|
  NODES.each do |node_config|
    config.vm.define node_config[:hostname] do |node|
      # Box
      node.vm.box = BOX

      # Synced folder
      config.vm.synced_folder "./", "/vagrant", type: "rsync",
        rsync__auto: true,
        rsync__exclude: ['.git/', './node_modules/', './server/node_modules/']

      # Network
      node.vm.hostname = node_config[:hostname]
      node.vm.network "private_network", ip: node_config[:ip]

      # Provision
      node.vm.provision "shell", inline: $script

      # Controller configuration
      if "controller".eql? node_config[:hostname] then
        # Network
        node.vm.network "forwarded_port", guest: 6443, host: 6443
        node.vm.network "forwarded_port", guest: 8080, host: 8080

        # Provision
        node.vm.provision "shell", inline: $controller
      end

      # Provider
      node.vm.provider "virtualbox" do |v|
        v.memory = VM_RAM
        v.cpus = VM_CPU
      end
      node.vm.provider "vmware_desktop" do |v|
        v.vmx["memsize"] = VM_RAM
        v.vmx["numvcpus"] = VM_CPU
      end
    end
  end
end
