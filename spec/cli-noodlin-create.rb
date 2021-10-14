# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodlin create' do
    hostname = HappyHelper.randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Make sure it's there
    noodle = "site= #{hostname}"
    assert_output("#{hostname} site=mars\n") { puts `bin/noodle #{noodle}` }
  end
end
