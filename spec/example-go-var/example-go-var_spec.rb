# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-go-var', :go do
  let (:app) { 'example-go-var' }

  it 'should respond with an http 200 and contain hello world' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("TEXT")
  end

  it 'should echo the request information' do
    rsp = get(route(app) + '/echo/')
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include('GET /echo/ HTTP/1.1')
  end
end