# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin param role+=app,web' do
    hostname = HappyHelper.randomhostname

    noodlin = "create -s mars -i host -p hr -P prod -a role=db #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodlin = "param role+=app,web #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure role param is present and correct
    noodle = "role= #{hostname}"
    assert_output("#{hostname} role=app,db,web\n") { puts `bin/noodle #{noodle}` }
  end
end
