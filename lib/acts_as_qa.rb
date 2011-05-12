# ActsAsQa
require 'yaml_db'
require 'random_data'
require 'acts_as_qa/acts_as_qa'
require 'acts_as_qa/parameters'
Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }

