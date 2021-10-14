# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin surplus' do
    hostname = HappyHelper.randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure it's there
    noodle = "site= #{hostname}"
    assert_output("#{hostname} site=mars\n") { puts `bin/noodle #{noodle}` }

    # Surplus it
    noodlin = "surplus #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure status changed
    noodle = "status=surplus #{hostname}"
    assert_output("#{hostname}\n") { puts `bin/noodle #{noodle}` }
  end
end
