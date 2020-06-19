# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin remove' do
    hostname = HappyHelper.randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure it's there
    noodle = "site= #{hostname}"
    assert_output("#{hostname} site=mars\n") { puts `bin/noodle #{noodle}` }

    # Remove it
    noodlin = "remove #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure it's gone
    noodle = "#{hostname}"
    assert_output("\n") { puts `bin/noodle #{noodle}` }
  end
end
