# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow noodlin param via PUT with JSON body' do
    hostname = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Use PUT /nodes/noodlin/ with a JSON array to set a param
    payload = ['param', "funky=town", hostname, '-w', 'test'].to_json
    put '/nodes/noodlin/', payload
    assert_equal 200, last_response.status

    # Verify the param was set
    noodle = "funky= #{hostname}"
    assert_output("#{hostname} funky=town\n") { puts `bin/noodle #{noodle}` }
  end
end
