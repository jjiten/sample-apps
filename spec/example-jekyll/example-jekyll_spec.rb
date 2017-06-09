# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-jekyll', :ruby do
  let (:app) { 'example-jekyll' }

  it 'should respond with an http 200 and contain Blog Posts' do
    rsp = get(route(app))
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("Blog Posts")
  end
end