require_relative 'spec_helper'

describe 'Noodle' do
  it "should noodle site=" do
    hostname = HappyHelper::randomhostname

    put "/nodes/#{hostname}", HappyHelper::node_hashdig
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    dotted_param = 'gum.address.zipcode'
    param_value  = '90210'
    dotted_fact  = 'chew.carrots.times'
    fact_value   = '12'

    # 1) blah.blah= for params:
    noodle = "#{dotted_param}= #{hostname}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname} #{dotted_param}=#{param_value}\n"){puts output}

    # 2) blah.blah= for facts:
    noodle = "#{dotted_fact}= #{hostname}"
    output = %x{bin/noodle #{noodle}}
    assert_output("#{hostname} #{dotted_fact}=#{fact_value}\n"){puts output}
  end
end
