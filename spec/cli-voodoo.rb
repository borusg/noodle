require_relative 'spec_helper'

describe 'Noodle' do
    it "voodoo should work" do
        # Create project=hr
        hostname_hr = HappyHelper::randomhostname
        noodlin = "create -s mars -i host -p hr -P prod -a voodoo=yes #{hostname_hr}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
        
        # Create project=warehouse
        hostname_warehouse = HappyHelper::randomhostname
        noodlin = "create -s mars -i host -p warehouse -P prod -a voodoo=yes #{hostname_warehouse}"
        assert_output(stdout="\n"){puts %x{bin/noodlin #{noodlin}}}
        
        # Make sure noodle hr only returns the first one
        noodle = "hr voodoo=yes"
        assert_output(stdout="#{hostname_hr}\n"){puts %x{bin/noodle #{noodle}}}
    end
end
