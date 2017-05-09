#!/usr/bin/env ruby

require "bundler"
Bundler.setup

# Stager for .NET CORE and ASP.NET Core apps
# Note that apps staged with this stager must have user set to root
# with --user root option on apc app create or apc app update

# Bring in apcera-stager-api
require "apcera-stager-api"

# Make sure stdout is sync'd.
STDOUT.sync = true

# Create new stager
stager = Apcera::Stager.new

# We do not add any dotnet dependency, thereby leaving choice of runtime package to user
# When they run apc app create command, they should specify some dotnet dependency

# Set the start path.
start_path = "/app"
puts "Setting start path to '#{start_path}'"
stager.start_path = start_path

# Download the package from the staging coordinator.
puts "Downloading Package..."
stager.download

# Extract the package to the "app" directory.
puts "Extracting Package..."
stager.extract("app")

# Determine whether app is source or dll
Dir.chdir("/tmp/staging/app")
if Dir.glob("*.csproj").size  > 0
   # We are staging source code
   puts "Found csproj file.  Will stage .NET source code"
   puts "Using csproj: #{Dir.glob("*.csproj")[0]}"

   # Add environment variables
   puts "Adding dotnet environment varibles to improve user experience when running from source"
   puts "Setting DOTNET_SKIP_FIRST_TIME_EXPERIENCE to true"
   stager.environment_add("DOTNET_SKIP_FIRST_TIME_EXPERIENCE", "true")
   puts "Setting DOTNET_CLI_TELEMETRY_OPTOUT to true"
   stager.environment_add("DOTNET_CLI_TELEMETRY_OPTOUT", "true")
   puts "Setting NUGET_XMLDOC_MODE to skip"
   stager.environment_add("NUGET_XMLDOC_MODE", "skip")

   # Set start command to run dotnet restore and dotnet run.
   # Both needed each time app starts since files created by restore not persisted
   start_cmd = "dotnet restore ; dotnet run"
elsif Dir.glob("*.deps.json").size > 0
  # We are staging a DLL
  puts "Found deps.json file. We will stage .NET DLL"
  dll  = Dir.glob("*.deps.json")[0].chomp(".deps.json") + ".dll"
  puts "Using dll: #{dll}"
  start_cmd = "dotnet #{dll}"
else
 # We cannot find anything to stage
 puts "Cannot find any .NET source or DLL to stage"
 stager.fail
end

# Set the start command.
puts "Setting start command to '#{start_cmd}'"
stager.start_command = start_cmd

# Finish staging, this will upload your final package to the
# staging coordinator.
puts "Completed Staging..."
stager.complete
