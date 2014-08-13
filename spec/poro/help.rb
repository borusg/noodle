require_relative 'spec_helper'

describe 'Hello World' do

  it 'should have hello world' do
    get '/help'
    assert last_response.must_be :ok?
    assert last_response.body.must_include "Noodle helps!"
  end
end

