require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE and giving full output" do
    put '/nodes/momo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"jupiter","full":"yes"}}'
    assert_equal last_response.status, 201
    Noodle::Node.gateway.refresh_index!

    get '/nodes/_/full=yes%20full'
    assert_equal last_response.status, 200
    assert_equal last_response.body, 'Name:   momo.example.com
Status: enabled
Ilk:    host
Params: 
  site=jupiter
  full=yes
Facts:  
  fqdn=momo.example.com
'
  end
end

