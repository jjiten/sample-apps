# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-go-system-info', :go do
  let (:app) { 'example-go-system-info' }

  it 'should respond with an http 200 and contains System Information' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("System Information")
    expect(rsp.body).to include("Target Operating System = linux")
  end
end