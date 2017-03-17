require 'open3'
require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN

class SimpleLog
  def self.log
    if @logger.nil?
      @logger = Logger.new STDOUT
      @logger.level = Logger::DEBUG
    end
    @logger
  end
end

# Run the apc command with the given parameters.
def apc(command)
  cmd_line = "apc #{command} --batch"
  execute(cmd_line)
end

def execute(command)
  stdout, stderr, status = Open3.capture3(command)

  SimpleLog.log.info { "STDOUT: #{stdout}" } unless stdout.empty?
  SimpleLog.log.info { "STDERR: #{stderr}" } unless stderr.empty?

  [stdout, stderr, status]
end

def get(url)
  uri = URI(url)
  Net::HTTP.get_response(uri)
end

# This janky way of getting the route, but at the moment we don't want to
# go an implement the API.
def route(app)
  cmd_line = "apc job show #{app} | grep Route | awk '{print $4}'"
  stdout, stderr, status = execute(cmd_line)
  stdout
end