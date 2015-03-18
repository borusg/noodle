require_relative 'spec_helper'

describe 'Noodle' do
    it "should noodlin param role=db" do
        hostname = HappyHelper::randomhostname

        noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}

        noodlin = "param role=db #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
    end
end
