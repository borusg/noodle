require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it 'allow sum to work' do
    post '/nodes/zqqz.example.com?now', HappyHelper.node_jupiter(magnitude: 4)
    assert_equal 201, last_response.status
    post '/nodes/zxxz.example.com?now', HappyHelper.node_jupiter(magnitude: 40)
    assert_equal 201, last_response.status

    get '/nodes/_/ilk=host%20magnitude+'.gsub('+', '%2B')
    assert_equal 200, last_response.status

    assert _(last_response.body).must_include 'magnitude=44.0'
  end
end
