namespace :nats_ping do
  sample_app = 'nats-ping'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      apc "docker run #{sample_app}-nats-server -i nats --restart always"
      apc "docker run #{sample_app}-client -i apcera/nats-ping-client --no-start"
      apc "job link #{sample_app}-client --to #{sample_app}-nats-server --name nats --port 4222"
      apc "job start #{sample_app}-client"
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    rspec sample_app
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    cd(sample_app) do
      apc "app delete #{sample_app}-client"
      apc "app delete #{sample_app}-nats-server"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the nats-ping sample application."
task :nats_ping => 'nats_ping:all'