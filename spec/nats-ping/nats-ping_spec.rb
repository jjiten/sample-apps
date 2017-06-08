# encoding: utf-8
require 'spec_helper'

RSpec.describe 'nats-ping', :nats, :go do
  let (:app) { 'nats-ping' }

  it 'should ping' do
    stdout, stderr, status = apc "job logs #{app}-client --no-tail"
    expect(stdout).to include("[PING] Latency:")
  end

  it 'should have a running nats-server' do
    stdout, stderr, status = apc "job logs #{app}-nats-server --no-tail"
    expect(stdout).to include("Listening for route connections on")
  end
end