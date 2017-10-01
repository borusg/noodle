require_relative 'client'

# TODO: Is a separate class for this premature optimization?
# TODO: Bubble up to target_ilk=default if not defined in the requested target_ilk?

# ilk=option target_ilk=host uniqueness=fqdn
# ilk=option target_ilk=sslcert uniqueness=fqdn
# ilk=option target_ilk=samlcert uniqueness=fqdn,component_type (component_type would be shibboleth|asimba)
class Noodle::Option
  def self.get(target_ilk='default')
    options = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk',target_ilk).go
    unless options.empty?
      return JSON.load()
    else
      # Hard-code some default options!
      return {
        'uniqueness'       => %w(ilk),
        'allowed_statuses' => %w{enabled disabled future surplus},
        'required_params'  => %w{ilk prodlevel project site status},
        'default_ilk'      => 'host',
        'default_status'   => 'enabled',
        'bareword_terms'   => %w{prodlevel project site},
        'limits'           => {
          'project'   => %w{hr financials lms registration warehouse},
          'prodlevel' => %w{dev preprod prod test},
          # TODO: Shirley, these could be classes instead of strings.
          'role'       => 'array',
          'stack'      => 'array',
          'gum'        => 'hash',
          'site'       => %w{jupiter mars moon neptune pluto uranus},
          'ilk'        => %w{host esx ucschassis ucsfi},
          'status'     => %w{disabled enabled future surplus},
        }
      }
    end
  end

  def self.option(ilk,option)
    return self.get(ilk)[option]
  end

  def self.option_limit(ilk,thing)
    return self.get(ilk)['limits'][thing]
  end
end
