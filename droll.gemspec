load 'lib/droll.rb'

Gem::Specification.new do |s|
  s.name            =  'droll'
  s.version         =  Droll.version
  s.authors         =  ['Chad Perrin']
  s.date            =  '2013-01-15'
  s.description     =  <<-EOF
    Droll is a Ruby library providing dice roller functionality, with a command
    line utility and an IRC bot as included user interfaces.  It was created
    with roleplaying gamers in mind, with a range of sophisticated capabilities
    for such users, and comes with command line interface and IRC dicebot front
    ends.
  EOF
  s.summary         =  'Droll - Dice Roller Library'
  s.email           =  'code@apotheon.net'
  s.files           =  [
    'COPYING',
    'README.md',
    'owl.txt',
    'lib/droll.rb',
    'bin/droll',
    'bin/drollbot',
    'etc/drollbot.conf.sample'
  ]
  s.homepage        =  'http://droll.fossrec.com'
  s.has_rdoc        =  true
  s.license         =  'OWL'
  s.bindir          =  'bin'
  s.executables     =  ['droll', 'drollbot']

  s.post_install_message    = <<-EOF
    Thank you for using droll.  In addition to library documentation in RDoc,
    the "droll" command line utility and "drollbot" IRC dicebot can both be
    executed from the shell prompt with a "-h" option for more help on how to
    use and/or configure these tools.
  EOF

  s.required_ruby_version   = '>= 1.9.0'
  s.add_runtime_dependency 'isaac', '~> 0.2'
end
