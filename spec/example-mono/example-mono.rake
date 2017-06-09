namespace :example_mono do
  sample_app = 'example-mono'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      cd("runtime") do
        apc "package build mono.conf --name #{current_path()}::mono"
      end

      cd("stager") do
        apc "stager create #{sample_app}-stager --start-command='./stager.rb' --staging=/apcera::ruby #{dc_tag()}"
        apc "staging pipeline create #{sample_app}-stager --name #{sample_app}-pipeline"
      end

      cd("app") do
        apc "app create #{sample_app} --staging #{sample_app}-pipeline --start #{dc_tag()}"
      end
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
      apc "staging pipeline delete #{sample_app}-pipeline"
      apc "stager delete #{sample_app}-stager"
      apc "app delete #{sample_app}"
      apc "package delete #{current_path()}::mono"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-mono sample application."
task :example_mono => 'example_mono:all'