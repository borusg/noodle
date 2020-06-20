# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail to create a node with the same name as an existing node' do
    post '/nodes/zozo.example.com?now', HappyHelper.node_jupiter
    assert_equal 201, last_response.status, 'First create'

    post '/nodes/zozo.example.com?now', HappyHelper.node_prod_jupiter
    assert_equal 400, last_response.status, 'Second create'
    assert _(last_response.body).must_include "Nope! Node is not unique\n"
  end
end
