# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-java-hello' do
  let (:app) { 'example-java-hello' }

  it 'should respond with an http 200 and contain hello world' do
    stdout, stderr, status = apc "job logs #{app} --no-tail"
    expect(stdout).to include("Hello, World")
  end
end