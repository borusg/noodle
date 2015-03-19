require_relative 'spec_helper'

describe 'Noodle' do
    it "should noodlin fact role=db" do
        hostname = HappyHelper::randomhostname

        noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}

        noodlin = "fact ram_gigs=2.0 #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}

        # Make sure ram_gigs fact is present
        noodle = "ram_gigs= #{hostname}"
        assert_output(stdout="#{hostname} ram_gigs=2.0\n"){puts %x{bin/noodle #{noodle}}}

    end
end
