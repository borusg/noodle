# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin param role+=db' do
    hostname = HappyHelper.randomhostname

    noodlin = "create -s mars -i host -p hr -P prod -a role=db #{hostname}"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure role param is present
    noodle = "franklin= #{hostname}"
    assert_output("#{hostname} franklin=\n") { puts `bin/noodle #{noodle}` }
  end
end
