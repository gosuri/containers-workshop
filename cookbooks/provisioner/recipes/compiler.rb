rubyver   = node[:rubyver]
nodever   = node[:nodever]

bundledir = "/app/vendor/bundle"
rubydir   = "/app/vendor/ruby/#{rubyver}"
nodedir   = "/app/vendor/node/#{nodever}" # execjs runtime
builddir = "#{Chef::Config[:file_cache_path]}/build"
cachedir  = "#{Chef::Config[:file_cache_path]}"
pkgs      = node[:packages][:buildtime]

# install and configure docker
include_recipe "docker"

# cache secrets base key
secrets_base = `cat #{cachedir}/secrets_base`.strip
if secrets_base == ''
  secrets_base = `date +%s | sha256sum | base64 | head -c 64`.strip
  file "#{cachedir}/secrets_base" do
    content secrets_base
  end
end

directory "#{cachedir}/app-compiler"

file "#{cachedir}/app-compiler/Dockerfile" do
  content <<-EOM 
FROM ubuntu
EXPOSE 9292

# Install base packages
RUN apt-get update && apt-get install -y #{pkgs.join(" ")}

# Set paths and environment variables
ENV PATH /app/bin:#{bundledir}/bin:#{rubydir}/bin:#{nodedir}/bin:$PATH
ENV GEM_PATH #{bundledir}/ruby/#{rubyver}
ENV RAILS_ENV production
ENV PORT 9292
ENV HOME /app
ENV SECRET_KEY_BASE #{secrets_base}

# Fetch the app source
RUN git clone https://github.com/gosuri/containers-demo-app.git /app

# Install ruby
RUN git clone https://github.com/sstephenson/ruby-build.git /ruby-build
RUN /ruby-build/bin/ruby-build #{rubyver} #{rubydir}

# Install nodejs
RUN curl http://nodejs.org/dist/v#{nodever}/node-v#{nodever}-linux-x64.tar.gz | tar xz
RUN mkdir -p #{nodedir}
RUN mv node-v#{nodever}-linux-x64/* #{nodedir}

# Install system gems
RUN gem install rubygems-update bundler --no-ri --no-rdoc
RUN update_rubygems
EOM
end

docker_image "app-compiler" do
  source "#{cachedir}/app-compiler/Dockerfile"
  action :build
  cmd_timeout 1200
end

build_steps = <<-SHELL
git pull
bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin -j5
rake assets:precompile
SHELL

build_steps.split("\n").each do | step |
  # assign a unique name
  ctnr = "app-compiler-#{(Time.now.to_f * 1000).to_i}"

  # run the step
  docker_container(ctnr) do
    cmd_timeout 600
    init_type false
    container_name ctnr
    image "app-compiler"
    working_directory "/app"
    command(step)
    action :run
  end

  # commit changes
  docker_container(ctnr) do
    repository "app-compiler"
    action :commit
  end

  # remove the container
  unless node[:inspect]
    docker_container(ctnr) do
      action :remove
    end
  end
end

bash "copy-build" do
  code <<-BASH
id=$(docker run -d app-compiler)
mkdir -p #{cachedir}/app-runtime
rm -rf #{cachedir}/app-runtime/app
docker cp $id:/app #{cachedir}/app-runtime
docker stop $id
docker rm $id
BASH
end
