#!/usr/bin/env ruby

require "bundler"
Bundler.setup
require "rest-client"
require "digest/sha1"

STAGER_URL = ENV["STAGER_URL"]

# Helper command to run a command, stream the output to stdout, and also capture
# if the command exited non-zero
def exe(cmd)
  result = system(cmd)
  if !result
    RestClient.post(STAGER_URL+"/failed", {})
    exit 1
  end
end

begin
  # download the package
  response = RestClient.get(STAGER_URL+"/data")
  File.open("pkg.tar.gz", "wb") do |f|
    f.write(response.to_str)
  end

  # create our working directory
  Dir.mkdir("site") unless Dir.exists?("site")

  # clean bundler environment and chdir into our working space
  Bundler.with_clean_env do
    Dir.chdir("site") do |apppath|
      # extract the file
      exe("tar xzf /app/pkg.tar.gz")

      # run bundle install
      exe("cd /app/site/app/www; bundle install --path /app/site-vendor/bundle --binstubs /app/site-vendor/bundle/bin --deployment")

      # set some environment variables to help with ruby handling the encoding
      # on files.
      ENV["LC_ALL"] = "en_US.UTF-8"
      ENV["LANG"] = "en_US.UTF-8"

      # generate the site
      exe("/app/site-vendor/bundle/bin/jekyll build --trace")

      # tar up the site conents
      Dir.chdir("_site") do |sitepath|
        exe("cd /app/site; tar czf /app/site.tar.gz .")
      end
    end
  end

  # upload it back
  sha1 = Digest::SHA1.file("site.tar.gz")
  File.open("site.tar.gz", "rb") do |f|
    response = RestClient.post(STAGER_URL+"/data?sha1=#{sha1.to_s}", f.read, { :content_type => "application/octet-stream" })
  end

  # ensure it uploaded ok
  if response.code == 200
    # successful, we're done
    RestClient.post(STAGER_URL+"/done", {})
    exit 0
  else
    # failed to upload, error out
    RestClient.post(STAGER_URL+"/failed", {})
    exit 1
  end
rescue => e
  puts "ERROR: #{e}"
  RestClient.post(STAGER_URL+"/failed", {})
  exit 1
end
