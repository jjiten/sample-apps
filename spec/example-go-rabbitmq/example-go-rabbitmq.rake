namespace :example_go_rabbitmq do
  sample_app = 'example-go-rabbitmq'

  # We alert users that we are not running anything because package is not provided.
  def alert_package_missing
    unless provided?("rabbitmq")
      SimpleLog.log.warn "There is no package that provides rabbitmq, skipping"
    end
  end

  desc "Install the #{sample_app} sample application."
  task :install do
    alert_package_missing

    provided("rabbitmq") do
      cd(sample_app) do
        apc "app create #{sample_app}"
        apc "service create #{sample_app}-service --type rabbitmq"
        apc "service bind #{sample_app}-service --job #{sample_app}"
        apc "app start #{sample_app}"
      end
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    alert_package_missing

    provided("rabbitmq") do
      rspec sample_app
    end
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    alert_package_missing

    provided("rabbitmq") do
      cd(sample_app) do
        apc "app delete #{sample_app}"
        apc "service delete #{sample_app}-service"
      end
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-go-rabbitmq sample application."
task :example_go_rabbitmq => 'example_go_rabbitmq:all'