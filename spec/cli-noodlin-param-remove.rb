# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin param -r role' do
    hostname = HappyHelper.randomhostname

    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Add role param
    noodlin = "param role=db #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure role param is present
    noodle = "role= #{hostname}"
    assert_output("#{hostname} role=db\n") { puts `bin/noodle #{noodle}` }

    # Remove role param
    noodlin = "param -r role #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure role param is gone
    noodle = "role= #{hostname}"
    assert_output("#{hostname}\n") { puts `bin/noodle #{noodle}` }
  end
end
