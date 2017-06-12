# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-perl-psgi', :go do
  let (:app) { 'example-perl-psgi' }

  it 'should respond with an http 200 and contain hello world' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Please, wait for just")
  end
end