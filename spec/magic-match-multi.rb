# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow finding by \'TERM1=~VALUE1 TERM2=~VALUE2\'' do
    post '/nodes/vovo.example.com?now', HappyHelper.node_neptune
    assert_equal 201, last_response.status
    post '/nodes/toto.example.com?now', HappyHelper.node_prod_neptune
    assert_equal 201, last_response.status

    get '/nodes/_/site=~nept%20prodlevel=~pro'
    assert_equal 200, last_response.status
    assert_equal "toto.example.com\n", last_response.body
  end
end
