require_relative 'spec_helper'

describe 'Noodle' do
    it "should noodlin remove" do
        hostname = HappyHelper::randomhostname
        # Create it
        noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
        
        # Make sure it's there
        noodle = "site= #{hostname}"
        assert_output(stdout="#{hostname} site=mars\n"){puts %x{bin/noodle #{noodle}}}

        # Remove it
        noodlin = "remove #{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}

        # Make sure it's gone
        noodle = "#{hostname}"
        assert_output(stdout="\n"){puts %x{bin/noodle #{noodle}}}
    end
end
