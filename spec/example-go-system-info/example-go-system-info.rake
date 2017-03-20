namespace :example_go_system_info do
  sample_app = 'example-go-system-info'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      apc "app create #{sample_app}"
      apc "app start #{sample_app}"
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    rspec sample_app
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    cd(sample_app) do
      apc "app delete #{sample_app}"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-go-system-info sample application."
task :example_go_system_info => 'example_go_system_info:all'