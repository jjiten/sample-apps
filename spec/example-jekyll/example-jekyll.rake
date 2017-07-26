namespace :example_jekyll do
  sample_app = 'example-jekyll'
  stager_jekyll = 'stager-jekyll'

  desc "Install the #{sample_app} sample application."
  task :install do
    apc "staging pipeline clone -n #{stager_jekyll}-static /apcera::static-site"

    cd(stager_jekyll) do
      apc "stager create #{stager_jekyll} --start-command='./stager.rb' --staging=/apcera::ruby --pipeline --allow-egress #{dc_tag()}"
    end

    apc "staging pipeline append #{stager_jekyll}-static #{stager_jekyll}"

    cd(sample_app) do
      apc "app create #{sample_app} --start --staging=#{stager_jekyll}-static --start #{dc_tag()}"
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
      apc_safe "staging pipeline delete #{stager_jekyll}-static"
      apc_safe "staging pipeline delete #{stager_jekyll}"
      apc_safe "stager delete #{stager_jekyll}"
      apc_safe "app delete #{sample_app}"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-jekyll sample application."
task :example_jekyll => 'example_jekyll:all'