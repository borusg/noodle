# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it "fail to delete a node that doesn't exist" do
    delete '/nodes/hoho.example.com'
    assert_equal 424, last_response.status
    assert _(last_response.body).must_include 'hoho.example.com does not exist'
  end
end
