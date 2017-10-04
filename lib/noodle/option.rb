require_relative 'client'

# TODO: Is a separate class for this premature optimization?
# TODO: Bubble up to target_ilk=default if not defined in the requested target_ilk?

# ilk=option target_ilk=host uniqueness=fqdn
# ilk=option target_ilk=sslcert uniqueness=fqdn
# ilk=option target_ilk=samlcert uniqueness=fqdn,component_type (component_type would be shibboleth|asimba)
class Noodle::Option
  def self.get(target_ilk='default')
    # Determine default options
    default_options = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk','default').go.results
    default_options = {
      'uniqueness_params' => %w(ilk),
      'required_params'   => %w{ilk prodlevel project site status},
      'default_ilk'       => 'host',
      'default_status'    => 'enabled',
      'bareword_terms'    => %w{prodlevel project site},
      'limits'            => {
        'gum'               => 'hash',
        'ilk'               => %w{host option esx ucschassis ucsfi},
        'prodlevel'         => %w{dev preprod prod test},
        'project'           => %w{hr financials lms noodle registration warehouse},
        'role'              => 'array',
        'site'              => %w{jupiter mars moon neptune pluto uranus},
        'stack'             => 'array',
        'status'            => %w{disabled enabled future surplus},
        # Not in alphabetical order because they match 3 above from outside the limits hash
        'bareword_terms'    => 'array',
        'limits'            => 'hash',
        'required_parms'    => 'array',
        'uniqueness_params' => 'array',
      }
    } if default_options.empty?

    # Find target_ilk options
    options = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk',target_ilk).go.results
    # Return target_ilk options merged with defaults, or defaults if no target_ilk options found
    unless options.empty?
      return JSON.load(default_options.merge(options.first).to_json)
    else
      # Hard-code some default options!
      return default_options
    end
  end

  def self.option(ilk,option)
    return self.get(ilk)[option]
  end

  def self.limit(ilk,thing)
    return self.get(ilk)['limits'][thing]
  end
end
