# -*- mode: ruby -*-
# vi: set ft=ruby :
#
current_dir = File.expand_path(File.dirname __FILE__)
HOSTNAME = ENV['BOXHOSTNAME'] || "airpair-workshop" 
BASE_BOX = ENV["BASEBOX"]     || "ubuntu/trusty64"
DEBUG    = ENV["DEBUG"]       || false
RUNLIST  = ENV['RUNLIST']     || %w(provisioner)
CHEFJSON = ENV['CHEFJSON']    || {
  mysql: {
    server_root_password: 'rootpass',
    server_debian_password: 'debpass',
    server_repl_password: 'replpass'
  }
}
VAGRANTFILE_API_VERSION = "2"
VAGRANT_REQUIRE_VERSION = ">= 1.5.0"

$shell = <<-BASH
# remove warning stdin: is not a tty
cat > /root/.profile <<EOM
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
tty -s && mesg
EOM

if [ ! -f "/usr/local/bin/chef-solo" ]; then
  export DEBIAN_FRONTEND=noninteractive
  # Upgrade headlessly (this is only safe-ish on vanilla systems)
  aptitude update &&
  apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade &&
  # Install Ruby and Chef
  aptitude install -y ruby1.9.1 ruby1.9.1-dev make &&
  sudo gem1.9.1 install --no-rdoc --no-ri chef --version 11.16.4
fi
BASH

Vagrant.require_version(VAGRANT_REQUIRE_VERSION)
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = BASE_BOX
  config.vm.hostname  = HOSTNAME 
  config.vm.network   :private_network, type: "dhcp"
  config.vm.network   "forwarded_port", guest: 8080, host: 8080, auto_correct: true
  config.vm.network   "forwarded_port", guest: 8081, host: 8081, auto_correct: true
  config.vm.network   "forwarded_port", guest: 9443, host: 9443, auto_correct: true
  config.vm.network   "forwarded_port", guest: 9292, host: 9292, auto_correct: true

  config.vm.provider 'virtualbox' do |v|
    v.memory = 2042
  end

  config.vm.provision :shell, inline: $shell
  config.vm.provision 'chef_solo' do |chef|
    chef.json     = CHEFJSON
    chef.run_list = RUNLIST
    chef.cookbooks_path = ["#{current_dir}/berks-cookbooks", "#{current_dir}/cookbooks"]
    if DEBUG
      chef.log_level = 'debug'
      chef.verbose_logging = true
    end
  end
end

# Fails gracefully if plugin is not found
# yields the block other wise
def with_plugin(plugin, &block)
  if Vagrant.has_plugin?(plugin)
    yield if block
  else
    log sprintf(ERR_MISSINGPLUGIN, plugin, plugin), :warning
  end
end

def log(msg, type=nil)
  msg = "==> #{type}: #{msg}"
  $stdout.puts case type
  when :info
    "\033[1m#{msg}\033[22m" # bold
  when :warning
    "\033[33m#{msg}\033[0m" # brown
  when :error
    "\033[31m#{msg}\033[0m" # red
  else msg # normal
  end
end

def read_tfvars
  tfvars = {}
  File.open(File.join current_dir, 'terraform.tfvars') do |file|
    file.each_line do |line|
      parts = line.split.compact
      tfvars[parts[0]] = parts[1]
    end
  end
end
