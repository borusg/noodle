require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow GETting a node after creating node via POST" do
    post '/nodes/gogo.example.com', HappyHelper::node_moon
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    r = MultiJson.load last_response.body
    assert_equal r['name'],             'gogo.example.com'
    assert_equal r['params']['ilk'],    'host'
    assert_equal r['params']['status'], 'surplus'
    assert_equal r['params']['site'],   'moon'
    assert_equal r['facts']['fqdn'],    'gogo.example.com'

    get '/nodes/gogo.example.com'
    assert_equal last_response.status, 200

    # TODO: DRY
    # TODO: Should fix body so ternary isn't needed here:
    r = last_response.body.empty? ? Hash.new : MultiJson.load(last_response.body)
    assert_equal r['name'],             'gogo.example.com'
    assert_equal r['params']['ilk'],    'host'
    assert_equal r['params']['status'], 'surplus'
    assert_equal r['params']['site'],   'moon'
    assert_equal r['facts']['fqdn'],    'gogo.example.com'
  end
end

