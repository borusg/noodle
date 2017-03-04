require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE and giving full output" do
    put '/nodes/momo.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter","full":"yes","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201
    Noodle::Node.gateway.refresh_index!

    get '/nodes/_/full=yes%20full'
    assert_equal last_response.status, 200
    assert_equal last_response.body, 'Name:   momo.example.com
Params: 
  ilk=host
  status=enabled
  site=jupiter
  full=yes
  project=hr
  prodlevel=dev
Facts:  
  fqdn=momo.example.com
'
  end
end

