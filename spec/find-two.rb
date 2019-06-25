require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by listing two FQDNs" do
    put '/nodes/yyz.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter", "funky":"town","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201

    put '/nodes/zzy.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter", "funky":"town","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201

    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/yyz.example.com%20zzy.example.com"
    assert_equal last_response.status, 200

    r = YAML.load last_response.body
    assert_equal r['parameters']['ilk'],    'host'
    assert_equal r['parameters']['status'], 'enabled'
    assert_equal r['parameters']['site'],   'jupiter'
  end
end

