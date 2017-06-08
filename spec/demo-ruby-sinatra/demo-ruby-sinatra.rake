namespace :demo_ruby_sinatra do
  sample_app = 'demo-ruby-sinatra'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      apc "staging pipeline clone -n #{sample_app}-ruby /apcera::ruby"

      cd("rspec-stager") do
        apc "stager create #{sample_app}-ruby-rspec -p rspec-stager --start-command=./rspec-stager --additive --allow-egress #{dc_tag()}"
      end

      apc "staging pipeline append #{sample_app}-ruby #{sample_app}-ruby-rspec"
      apc "app create #{sample_app} --start --staging=#{sample_app}-ruby #{dc_tag()}"
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    rspec sample_app
  end

  desc "Restart the #{sample_app} sample application."
  task :restart do
    cd(sample_app) do
      apc "app restart #{sample_app}"
    end
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    cd(sample_app) do
      apc "staging pipeline delete #{sample_app}-ruby"
      apc "stager delete #{sample_app}-ruby-rspec"
      apc "app delete #{sample_app}"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the demo-ruby-sinatra sample application."
task :demo_ruby_sinatra => 'demo_ruby_sinatra:all'