require_relative 'spec_helper'

describe 'Noodle' do
    it "should echo hi in shell" do
        hostname = SecureRandom.uuid
        noodlin = "create -s mars -i host -p hr -P prod #{hostname}.example.com"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
    end
end
