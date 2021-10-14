# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin param role=db for multiple nodes' do
    hostname1 = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname1} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    hostname2 = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname2} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodlin = "param role=db #{hostname1} #{hostname2} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure role param is present for both
    noodle = "role= #{hostname1}"
    assert_output("#{hostname1} role=db\n") { puts `bin/noodle #{noodle}` }

    noodle = "role= #{hostname2}"
    assert_output("#{hostname2} role=db\n") { puts `bin/noodle #{noodle}` }
  end
end
