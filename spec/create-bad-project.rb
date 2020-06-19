# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail to create a node with a bad project name' do
    post '/nodes/pigglywiggly.example.com?now', HappyHelper.node_piggly
    assert_equal 400, last_response.status
    assert _(last_response.body).must_include 'project is not one of these:'
  end
end
