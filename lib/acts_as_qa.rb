# ActsAsQa
module ActsAsQA

  class QAA
    def self.test(p)
      puts "TEST #{p}"
    end
    
    def self.qa(params)
      #puts "[p] = #{params.inspect}"
      
      parameters = {}
      params.each do|k, v| 
        parameters[k.to_sym] = v
      end     

      parameters
    end
    def self.load_tasks
      if File.exists?('Rakefile')
        load 'Rakefile'
        return true
      else
        return false
      end
    end
  end
  
  class Display
    def self.colorize(text, color_code) 
      "\e[#{color_code}m#{text}\e[0m"
    end
  end

end
require 'acts_as_qa/railtie'
require 'acts_as_qa/parameters'