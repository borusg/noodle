require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodle site=" do
    hostname = HappyHelper::randomhostname

    # Create node
    noodlin = "create -s mars -i host -p hr -P prod #{hostname}"
    output = %x{bin/noodlin #{noodlin}}
    assert_output("\n"){puts output}

    # Set a deep hash value on the 'gum' param (TODO: noodlin create's -a doesn't yet get this right)
    dotted = 'gum.address.zipcode'
    value  = '90210'
    noodlin = "param #{dotted}=#{value} #{hostname}"
    output = %x{bin/noodlin #{noodlin}}
    assert_output("\n"){puts output}
    #
    # Make sure hash digging works:
    noodle = "#{dotted}= #{hostname}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname} #{dotted}=#{value}\n"){puts output}

    # Set a deep hash value on the 'chew' fact (TODO: noodlin create's -a doesn't yet get this right)
    dotted = 'chew.carrots.times'
    value  = '12'
    noodlin = "fact #{dotted}=#{value} #{hostname}"
    output = %x{bin/noodlin #{noodlin}}
    assert_output("\n"){puts output}
    #
    # Make sure hash digging works:
    noodle = "#{dotted}= #{hostname}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname} #{dotted}=#{value}\n"){puts output}
  end
end
