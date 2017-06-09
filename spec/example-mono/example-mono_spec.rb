# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-mono', :ruby do
  let (:app) { 'example-mono' }

  it 'should respond with an http 200 and contain "Conversion to Upper Case"' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Conversion to Upper Case")
  end
end