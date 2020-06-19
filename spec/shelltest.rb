# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'echo hi in shell' do
    assert_output("hi\n"){puts %x{echo hi}}
  end
end
