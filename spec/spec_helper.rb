require 'open3'
require 'logger'
require 'json'
require 'net/http'

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

# Run the apc command with the given parameters. Will _not_ raise an exception
# if a non-zero return code is returned from the command.
def apc_safe(command)
  cmd_line = "apc #{command} --batch"
  SimpleLog.log.info { "CMD: #{cmd_line}" }
  stdout, stderr, status = execute(cmd_line)

  SimpleLog.log.info { "STDOUT: #{stdout}" } unless stdout.empty?
  SimpleLog.log.info { "STDERR: #{stderr}" } unless stderr.empty?

  [stdout, stderr, status]
end

# Run the apc command with the given parameters.  Will raise an exception if
# a non-zero return code is returned from the command.
def apc(command)
  stdout, stderr, status = apc_safe(command)

  if status.exitstatus != 0
    raise "The command 'apc #{command} --batch' failed with a return code #{status.exitstatus}"
  end

  [stdout, stderr, status]
end

def execute(command)
  Open3.capture3(command)
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
  stdout.strip
end

# If provided then true, else false
def provided?(name)
  cmd_line = "apc package list -ns / --json"
  stdout, stderr, status = execute(cmd_line)
  JSON.parse(stdout).each do |package|
    if package['provides']
      package['provides'].each do |providers|
        if providers['name'] == name
          return true
        end
      end
    end
  end
  false
end

def watch_logs(application, string_to_watch_for, number_of_times, sleep_between)
  for i in 1..number_of_times
    stdout, stderr, status = apc "job logs #{application} --no-tail"

    if stdout.include? string_to_watch_for or stderr.include? string_to_watch_for
      return true
    end

    sleep sleep_between
  end

  return false
end

def current_path()
  stdout, stderr, status = execute("apc cd | awk '{print $3}'")
  stdout.strip()[1..-2]
end

def provided(name)
  if provided? name
    yield
  end
end

def storage_name()
  ENV['STORAGE'] ? ENV['STORAGE'] : "/apcera/providers::apcfs-ha"
end

def dc_tag()
  ENV['DC_TAG'] ? "-ht #{ENV['DC_TAG']}" : ""
end