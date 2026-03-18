# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'return 404 for unknown routes' do
    get '/this/route/does/not/exist'
    assert_equal 404, last_response.status
    assert _(last_response.body).must_include 'I dunno what you want'
  end
end
