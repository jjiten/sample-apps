# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-java-jar-server-env', :java do
  let (:app) { 'example-java-jar-server-env' }

  it 'should respond with an http 200 and contain hello world' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Hello, World!")
  end
end