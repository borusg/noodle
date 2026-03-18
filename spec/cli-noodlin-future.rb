# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin future' do
    hostname = HappyHelper.randomhostname
    # Create as surplus
    noodlin = "create -s mars -i host -p hr -P prod -S surplus #{hostname} -w test"
    `bin/noodlin #{noodlin}`

    # Mark it future
    noodlin = "future #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure status changed to future
    noodle = "status=future #{hostname}"
    assert_output("#{hostname}\n") { puts `bin/noodle #{noodle}` }
  end
end
