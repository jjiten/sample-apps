# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-go', :go do
  let (:app) { 'example-go' }

  it 'should respond with an http 200 and contain hello world' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("hello, world!")
  end
end