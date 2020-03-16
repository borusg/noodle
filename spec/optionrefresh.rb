require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow refreshing options" do
    noodlin = 'create -i option -p noodle -P prod -s mars -a target_ilk=default default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    noodlin = 'param limits.project=hr,financials,lms,noodle,registration,test,warehouse default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    assert_output("Your options had a nap and they are nicely refreshed.\n"){puts %x{bin/noodlin optionrefresh}}

    put '/nodes/zippyziggy.example.com', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status
  end
end

