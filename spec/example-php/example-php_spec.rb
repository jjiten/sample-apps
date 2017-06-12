# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-php', :go do
  let (:app) { 'example-php' }

  it 'should respond with an http 200 and contain "Hello, World!"' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Hello, World!")
  end
end