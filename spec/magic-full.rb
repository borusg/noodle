require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE and giving full output" do
    put '/nodes/momo.example.com', HappyHelper::node_jupiter_full
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/full=yes%20full'
    assert_equal last_response.status, 200
    assert_equal last_response.body, 'Name:   momo.example.com
Params: 
  created_by=spec
  ilk=host
  status=enabled
  site=jupiter
  full=yes
  project=hr
  prodlevel=dev
  last_updated_by=spec
Facts:  
  fqdn=momo.example.com
'
  end
end

