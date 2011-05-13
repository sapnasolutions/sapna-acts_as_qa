Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.author            = "SapnaSolutions"
  s.email             = "contact@sapnasolutions.com"
  s.name              = 'acts_as_qa'
  s.version           = '1.0.1'
  s.description       = 'Check the routes of a Rails Application'
  s.date              = '2011-05-05'
  s.summary           = 'Check the routes of a Rails Application'
  s.require_paths     = %w(lib)
  s.files             = Dir['lib/**/*', 'rails/**/*', 'Rakefile', 'README.md', 'MIT-LICENSE']
  s.add_dependency 'random_data'
  s.add_dependency 'yaml_db'
end
