# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin enable' do
    hostname = HappyHelper.randomhostname
    # Create as surplus
    noodlin = "create -s mars -i host -p hr -P prod -S surplus #{hostname} -w test"
    `bin/noodlin #{noodlin}`

    # Enable it
    noodlin = "param status=enabled #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure status changed to enabled
    noodle = "status=enabled #{hostname}"
    assert_output("#{hostname}\n") { puts `bin/noodle #{noodle}` }
  end
end
