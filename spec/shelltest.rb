require_relative 'spec_helper'

describe 'Noodle' do
    it "should echo hi in shell" do
        assert_output(stdout="hi\n"){puts %x{echo hi}}
    end
end
