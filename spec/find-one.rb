require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by FQDN" do
    put '/nodes/zyyz.example.com', HappyHelper::node_funky_jupiter
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/zyyz.example.com"
    assert_equal last_response.status, 200

    r = YAML.load last_response.body
    assert_equal r['parameters']['ilk'],    'host'
    assert_equal r['parameters']['status'], 'enabled'
    assert_equal r['parameters']['site'],   'jupiter'
  end
end

