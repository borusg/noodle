require_relative 'spec_helper'

describe "Noodle" do
  it "should allow GETting a node after creating node via POST" do
    post '/nodes/jojo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert_equal last_response.status, 201

    r = MultiJson.load last_response.body
    assert_equal r['name'],           'jojo.example.com'
    assert_equal r['ilk'],            'host'
    assert_equal r['status'],         'surplus'
    assert_equal r['params']['site'], 'moon'

    # If you don't wait, the node doesn't really exist in Elasticsearch yet!
    sleep 1

    get '/nodes/jojo.example.com'
    assert_equal last_response.status, 200

    # TODO: DRY
    r = MultiJson.load last_response.body
    assert_equal r['name'],           'jojo.example.com'
    assert_equal r['ilk'],            'host'
    assert_equal r['status'],         'surplus'
    assert_equal r['params']['site'], 'moon'
  end
end

