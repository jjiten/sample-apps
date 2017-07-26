namespace :example_perl_psgi do
  sample_app = 'example-perl-psgi'

  desc "Install the #{sample_app} sample application."
  task :install do
    cd(sample_app) do
      apc "app create #{sample_app} --start #{dc_tag()}"
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

desc "Install, test, and teardown the example-perl-psgi sample application."
task :example_perl_psgi => 'example_perl_psgi:all'