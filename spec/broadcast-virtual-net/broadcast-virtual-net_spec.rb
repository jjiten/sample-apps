# encoding: utf-8
require 'spec_helper'

RSpec.describe 'broadcast-virtual-net' do
  let (:app) { 'broadcast-virtual-net' }

  it 'should recieve HELLO!' do
    stdout, stderr, status = apc "job logs #{app}-cast-listen --no-tail"
    expect(stdout).to include("HELLO!")
  end
end