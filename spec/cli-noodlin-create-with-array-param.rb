# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin create with array param' do
    hostname = HappyHelper.randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod -a role=db,app #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure it's there and that role is an array
    noodle = "role= #{hostname}"
    assert_output("#{hostname} role=app,db\n") { puts `bin/noodle #{noodle}` }
  end
end
