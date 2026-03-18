# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin disabled' do
    hostname = HappyHelper.randomhostname
    # Create as enabled (default)
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Disable it
    noodlin = "disabled #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure status changed to disabled
    noodle = "status=disabled #{hostname}"
    assert_output("#{hostname}\n") { puts `bin/noodle #{noodle}` }
  end
end
