# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin fact role=db' do
    hostname = HappyHelper.randomhostname

    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodlin = "fact ram_gigs=2.0 #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure ram_gigs fact is present
    noodle = "ram_gigs= #{hostname}"
    assert_output("#{hostname} ram_gigs=2.0\n") { puts `bin/noodle #{noodle}` }
  end
end
