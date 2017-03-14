#!/usr/bin/ruby

require 'securerandom'

#bin/noodlin create -i host -s neptune -p hr -P dev -f cpus=2 -f ramgigs=16 -f diskgigs=8 -a role=web,mariadb marille.example.com

project   = %w{hr financials lms registration warehouse}
prodlevel = %w{dev preprod prod test}
status    = %w{disabled enabled future surplus}
site      = %w{jupiter mars moon neptune pluto uranus}
ilk       = %w{host esx ucschassis ucsfi}

cmd = []

1000.times do
    proj = project[rand(project.size)]
    prod = prodlevel[rand(prodlevel.size)]
    s    = site[rand(site.size)]
    i    = ilk[rand(ilk.size)]
    cpus = rand(16)
    ram  = rand(64)
    disk = rand(1024)
    fqdn = SecureRandom.uuid.gsub('-','') + '.example.com'

    cmd << "bin/noodlin create -i host -s #{s} -p #{proj} -P #{prod} -f cpus=#{cpus} -f ramgigs=#{ram} -f diskgigs=#{disk} #{fqdn}"
end

puts cmd.join("\n")
