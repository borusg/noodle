require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow DELETE everything via /nodes' do
    post '/nodes/sisi.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status
    post '/nodes/titi.example.com?now', HappyHelper.node_mars
    assert_equal 201, last_response.status

    delete '/nodes'
    assert_equal 200, last_response.status

    get '/nodes'
    assert_equal 200, last_response.status
    assert_equal '', last_response.body
  end
end
