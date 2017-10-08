require_relative 'client'

# TODO: Bootstrapping options into ilk=option, emptyness, etc etc is
# far too finicky. Rework this whole thing

# TODO: Is a separate class for this premature optimization?
# TODO: Bubble up to target_ilk=default if not defined in the requested target_ilk?

# ilk=option target_ilk=host uniqueness=fqdn
# ilk=option target_ilk=sslcert uniqueness=fqdn
# ilk=option target_ilk=samlcert uniqueness=fqdn,component_type (component_type would be shibboleth|asimba)
class Noodle::Option
  def self.get(target_ilk='default')
    # Determine default options
    # TODO: Prettier
    default_options = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk','default').go.results.first
    if default_options.nil?
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
          # Not in alphabetical order because they match the ones above outside the limits hash
          'bareword_terms'    => 'array',
          'limits'            => 'hash',
          'required_parms'    => 'array',
          'uniqueness_params' => 'array',
        }
      }
    else
      default_options = JSON.load(default_options.to_json)['params']
    end

    # Find target_ilk options
    options = Noodle::Search.new(Noodle::Node).equals('ilk','option').equals('target_ilk',target_ilk).go.results
    # Return target_ilk options merged with defaults, or defaults if no target_ilk options found
    unless options.empty?
      return JSON.load(default_options.merge(options.first['params']).to_json)
    else
      return default_options
    end
  end

  def self.option(ilk,option)
    r = self.get(ilk)[option]
    return self.emptyness(ilk,option) if r.nil?
    return r
  end

  # TODO: need .empty? because who knows if caller wants string or array, etc
  def self.limit(ilk,thing)
    limits = self.get(ilk)['limits']
    return [] if limits.nil?
    limit = limits[thing]
    return [] if limit.nil?
    return limit
  end

  def self.emptyness(ilk,option)
    return [] if self.limit(ilk,option) == 'array'
    return {} if self.limit(ilk,option) == 'hash'
    return ''
  end
end
