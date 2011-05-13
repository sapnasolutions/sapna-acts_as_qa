require 'acts_as_qa'
require 'rails'
module AAQA
  class Railtie < Rails::Railtie
    railtie_name :acts_as_qa

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), '..', 'tasks', '**/*.rake')].each { |rake| load rake }
    end
  end
end