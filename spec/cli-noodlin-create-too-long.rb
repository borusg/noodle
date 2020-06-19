# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail to noodlin create when hostname is too long' do
    hostname = 'this-is-way-too-long-' + HappyHelper.randomhostname
    # Create it
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    # Make sure it fails
    assert_output("Sorry, one or more of your short node names was longer than 15 characters. Exiting.\nYour node names were:\n#{hostname}\n") { puts `bin/noodlin #{noodlin}` }
  end
end
