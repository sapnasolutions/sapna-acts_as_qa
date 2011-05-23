require 'acts_as_qa'
module AAQA
  if defined? Rails::Railtie
    require 'rails'
    class Railtie < Rails::Railtie
      rake_tasks do
        Dir[File.join(File.dirname(__FILE__), '..', 'tasks', '**/*.rake')].each { |rake| load rake }
      end
    end
  end
end