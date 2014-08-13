require_relative 'spec_helper'

describe 'Noodle' do
  it 'should give a helpful message' do
    get '/help'
    assert last_response.must_be :ok?
    assert last_response.body.must_include "Noodle helps!"
  end
end

