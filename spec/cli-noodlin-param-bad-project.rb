# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin param role=db' do
    hostname = HappyHelper.randomhostname

    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodlin = "param project=badproject #{hostname} -w test"
    assert_output(/project is not one of these:.*It is badproject./) { puts `bin/noodlin #{noodlin}` }
  end
end
