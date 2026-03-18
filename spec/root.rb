# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'respond to GET /' do
    get '/'
    assert_equal 200, last_response.status
    assert_equal "Noodles are delicious\n", last_response.body
  end
end
