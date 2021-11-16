# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allows summation to work via FACT+' do
    post '/nodes/somesum.example.com?now', HappyHelper.node_jupiter
    assert_equal 201, last_response.status

    r = MultiJson.load last_response.body
    assert_equal 'somesum.example.com', r['name']
    assert_equal 'host',                r['params']['ilk']
    assert_equal 'jupiter',             r['params']['site']
    assert_equal 4.0,                   r['facts']['storage_gigs']

    noodle = 'ilk=host storage_gigs+'
    assert_output("storage_gigs=4.0\n") { puts `bin/noodle #{noodle}` }
  end
end
