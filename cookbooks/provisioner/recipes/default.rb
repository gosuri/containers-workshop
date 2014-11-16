#
# Cookbook Name:: provisioner
# Recipe:: default
#
# Copyright (c) 2014 Greg Osuri, All Rights Reserved.

rubyver   = "2.1.2"
nodever   = "0.10.33"
bundledir = "/app/vendor/bundle"
rubydir   = "/app/vendor/ruby/#{rubyver}"
nodedir   = "/app/vendor/node-0.10.33" # execjs runtime

# runtime packages
pkgs = %w{
}

# compile packages
build_pkgs = pkgs +  %w{
  unzip 
  git
  git-core
  curl
  zlib1g-dev
  build-essential
  libssl-dev
  libreadline-dev
  libyaml-dev
  libsqlite3-dev
  sqlite3
  libxml2-dev
  libxslt1-dev
  libcurl4-openssl-dev
  python-software-properties
}

pkgs.each { |pkg| package(pkg) }

builddir = "#{Chef::Config[:file_cache_path]}/build"

# install and configure docker
include_recipe "docker"

# For development use only 
execute "kill-all-containers" do
  command "docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)"
  # comment below to nuke all containers
  # action :nothing
  ignore_failure true
end

# save current timestamp
timestamp = Time.new.strftime('%Y%m%d%H%M')
cachedir  = "#{Chef::Config[:file_cache_path]}"

file "#{cachedir}/app_build_docker" do
  content <<-EOM 
FROM ubuntu

# Install base packages
RUN apt-get update && apt-get install -y #{build_pkgs.join(" ")}

# Set PATHs and environment variables
ENV PATH /app/bin:#{bundledir}/bin:#{rubydir}/bin:#{nodedir}/bin:$PATH
ENV GEM_PATH #{bundledir}/ruby/#{rubyver}
ENV RAILS_ENV production
ENV PORT 9292
ENV HOME /app

# Fetch the app source
RUN git clone https://github.com/gosuri/containers-demo-app.git /app

# Install Ruby
RUN git clone https://github.com/sstephenson/ruby-build.git /ruby-build
RUN /ruby-build/bin/ruby-build #{rubyver} #{rubydir}

# Install Node 
RUN curl http://nodejs.org/dist/v#{nodever}/node-v#{nodever}-linux-x64.tar.gz | tar xz
RUN mv node-v0.10.33-linux-x64 #{nodedir}

# Install ruby-gems and bundler
RUN gem install rubygems-update bundler --no-ri --no-rdoc
RUN update_rubygems

# Install gem bundle
RUN cd /app && bundle install --path vendor/bundle --standalone --jobs 10  --deployment

# Compile assets
RUN cd /app && bundle exec rake assets:precompile

# Run app
EXPOSE $PORT
CMD cd /app && bundle exec puma config.ru -p $PORT
EOM
end

docker_image "app_build" do
  source "#{cachedir}/app_build_docker"
  action :build
  cmd_timeout 1200
end

# cache secrets base key
secrets_base = `cat #{cachedir}/secrets_base`.strip
if secrets_base == ''
  secrets_base = `date +%s | sha256sum | base64 | head -c 64`.strip
  file "#{cachedir}/secrets_base" do
    content secrets_base
  end
end

docker_container "app_build" do
  port "9292:9292"
  cmd_timeout 1200
  env "SECRET_KEY_BASE=#{secrets_base}"
  action :run
end

docker_container "app_build" do
  repository "builds"
  action :commit
end

docker_container "app_build" do
  action :stop
end
