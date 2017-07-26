namespace :example_java_jdbc_mysql do
  sample_app = 'example-java-jdbc-mysql'

  def alert_package_missing
    unless provided?("java")
      SimpleLog.log.warn "There is no package that provides java, skipping"
    end
  end

  desc "Install the #{sample_app} sample application."
  task :install do
    alert_package_missing

    provided("java") do
      cd(sample_app) do
        password = rand(36**16).to_s(36)  # Create a random 16 character password
        apc "docker run #{sample_app}-mysql-server --restart always --image mysql --tag 5.7.13 --port 3306 --provider #{storage_name()} --env-set MYSQL_ROOT_PASSWORD=#{password} #{dc_tag()}"
        watch_logs("#{sample_app}-mysql-server", "mysqld: ready for connections", 60, 10)  # Wait up to 10 minutes to have mysql startup
        sleep 60  # TODO Fix race condition.  It is possible that the required ports are not setup before calling provider register.
        apc "provider register #{sample_app}-mysql-provider --job #{sample_app}-mysql-server --type mysql --url mysql://root:#{password}@#{sample_app}-mysql-server --description 'MySQL DB for #{sample_app}'"
        apc "service create #{sample_app}-mysql-service -t mysql --provider #{sample_app}-mysql-provider"
        apc "app create #{sample_app} --disable-routes #{dc_tag()}"
        apc "service bind #{sample_app}-mysql-service -j #{sample_app}"
        apc "app start #{sample_app}"
      end
    end
  end

  desc "Test the #{sample_app} sample application after it is deployed."
  task :test do
    alert_package_missing

    provided("java") do
      rspec sample_app
    end
  end

  desc "Restart the #{sample_app} sample application."
  task :restart do
    alert_package_missing

    provided("java") do
      cd(sample_app) do
        apc "app restart #{sample_app}"
      end
    end
  end

  desc "Teardown the #{sample_app} sample application."
  task :teardown do
    alert_package_missing

    provided("java") do
      cd(sample_app) do
        apc_safe "app delete #{sample_app}"
        apc_safe "service delete #{sample_app}-mysql-service"
        apc_safe "provider delete #{sample_app}-mysql-provider"
        apc_safe "job delete #{sample_app}-mysql-server --delete-services"
      end
    end
  end

  task :all => [:install, :test, :teardown]
end

desc "Install, test, and teardown the example-java-jdbc-mysql sample application."
task :example_java_jdbc_mysql => 'example_java_jdbc_mysql:all'