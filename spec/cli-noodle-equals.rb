# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'noodle site=' do
    hostname = HappyHelper.randomhostname
    noodlin = "create -s mars -i host -p hr -P prod #{hostname} -w test"
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodle = "site= #{hostname}"
    assert_output("#{hostname} site=mars\n") { puts `bin/noodle #{noodle}` }
  end
end
