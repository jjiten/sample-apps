namespace :broadcast_virtual_net do
  sample_app = 'broadcast-virtual-net'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      cd('sender') do
        apc "app create #{sample_app}-cast-send --disable-routes #{dc_tag()}"
      end

      cd('listener') do
        apc "app create #{sample_app}-cast-listen --disable-routes #{dc_tag()}"
      end

      apc "network create #{sample_app}-mynet"
      apc "network join #{sample_app}-mynet --job #{sample_app}-cast-send"
      apc "network join #{sample_app}-mynet --job #{sample_app}-cast-listen"
      apc "job update #{sample_app}-cast-send --network #{sample_app}-mynet --broadcast-enable"
      apc "job update #{sample_app}-cast-listen --network #{sample_app}-mynet --broadcast-enable"
      apc "app start #{sample_app}-cast-send"
      apc "app start #{sample_app}-cast-listen"
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    rspec sample_app
  end

  desc "Restart the #{sample_app} sample application."
  task :restart do
    cd(sample_app) do
      apc "app restart #{sample_app}-cast-send"
      apc "app restart #{sample_app}-cast-listen"
    end
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    cd(sample_app) do
      apc "app delete #{sample_app}-cast-send"
      apc "app delete #{sample_app}-cast-listen"
      apc "network delete #{sample_app}-mynet"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the broadcast-virtual-net sample application."
task :broadcast_virtual_net => 'broadcast_virtual_net:all'