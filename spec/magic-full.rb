require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE and giving full output" do
    put '/nodes/momo.example.com', HappyHelper::node_jupiter_full
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/full=yes%20full'
    assert_equal 200, last_response.status
    # assert_match so it ignores timestamps
    assert_match 'Name:   momo.example.com
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
', last_response.body
  end
end

