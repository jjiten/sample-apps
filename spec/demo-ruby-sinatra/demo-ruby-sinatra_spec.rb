# encoding: utf-8
require 'spec_helper'

RSpec.describe 'demo-ruby-sinatra' do
  let (:app) { 'demo-ruby-sinatra' }

  it 'should respond with an http 200 and contain Sinatra Sample' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Sinatra Sample")
  end
end