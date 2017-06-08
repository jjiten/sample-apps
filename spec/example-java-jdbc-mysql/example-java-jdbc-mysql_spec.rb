# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-java-jdbc-mysql', :mysql, :storage, :java do
  let (:app) { 'example-java-jdbc-mysql' }

  it 'should have a successful MySQL connection' do
    stdout, stderr, status = apc "job logs #{app} --no-tail"
    expect(stdout).to include("MySQL Connection Successful!")
  end
end