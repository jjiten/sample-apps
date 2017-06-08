# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-bash', :bash do
  let (:app) { 'example-bash' }

  it 'should respond with an http 200 and contain sample text' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Sample Index.html")
  end
end