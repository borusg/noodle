# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail with unknown noodlin command' do
    hostname = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    payload = ['badcommand', hostname, '-w', 'test'].to_json
    put '/nodes/noodlin/', payload
    assert_equal 400, last_response.status
    assert _(last_response.body).must_include 'Unknown noodlin command: badcommand'
  end
end
