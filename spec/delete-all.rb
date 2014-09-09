require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow DELETE everything via /nodes" do
    post '/nodes/sisi.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert_equal last_response.status, 201
    post '/nodes/titi.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"mars"}}'
    assert_equal last_response.status, 201
    Noodle::Node.gateway.refresh_index!

    delete '/nodes'
    assert_equal last_response.status, 200

    get '/nodes'
    assert_equal last_response.status, 200
    assert_equal last_response.body, ''
  end
end

