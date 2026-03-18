# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin fact -r factname' do
    hostname = HappyHelper.randomhostname

    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Add a fact
    noodlin = "fact ram_gigs=8.0 #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure fact is present
    noodle = "ram_gigs= #{hostname}"
    assert_output("#{hostname} ram_gigs=8.0\n") { puts `bin/noodle #{noodle}` }

    # Remove the fact
    noodlin = "fact -r ram_gigs #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure fact is gone
    noodle = "ram_gigs= #{hostname}"
    assert_output("#{hostname} ram_gigs=\n") { puts `bin/noodle #{noodle}` }
  end
end
