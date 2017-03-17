# encoding: utf-8
require 'spec_helper'

RSpec.describe 'example-go-rabbitmq' do
  let (:app) { 'example-go-rabbitmq' }

  it 'should be able to push an pop messages' do
    route = route(app)
    random_number = rand(10000)

    # Push a random number
    rsp = get("#{route}/push/#{random_number}")
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("published: \"/push/#{random_number}\"")

    # Pop a random number
    rsp = get("#{route}/pop")
    expect(rsp.code).to eq("200")
    expect(rsp.body).to include("popped: \"/push/#{random_number}\"")
  end
end