namespace :example_php_fpm do
  sample_app = 'example-php-fpm'

  desc "Install the #{sample_app} sample application."
  task :install do
    provided?("php-fpm-nginx") do
      cd(sample_app) do
        apc "app create #{sample_app} --start #{dc_tag()}"
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
      apc_safe "app delete #{sample_app}"
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-php-fpm sample application."
task :example_php_fpm => 'example_php_fpm:all'