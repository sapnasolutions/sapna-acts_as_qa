module ActsAsQA

  class QAA    
    
    def self.qa(params)
        parameters = {}
        params.each do|k, v|   
          parameters[k.to_sym] = v    
        end     
        parameters_list=[]
        parameters_multiply(parameters_list, parameters)
        parameters_list
    end
    
    def self.parameters_multiply(parameters_list, parameters)
      done = []
      flag = 0
      evaluate_object(parameters[:parameters])
      Hash[[parameters[:parameters].select{|k, v| v.class==Symbol or v.class==Array}.first]].each do |k, v|
        flag=1
        if v.class==Symbol
          value = v.to_s.split('_').collect{|x| x.capitalize!}.join('')
          if self.datatypes.include?(v)
            list_value = parameters.dup
            list_value[:parameters] = parameters[:parameters].dup
            list_value[:parameters][k]=random_value(v)
            done << k
            parameters_multiply(parameters_list, list_value)
          elsif (eval(value).descends_from_active_record? rescue false)
            list_value = parameters.dup
            list_value[:parameters] = parameters[:parameters].dup
            value = eval(value)
            list_value[:parameters][k]=(eval("#{value}.all.map(&:#{k.to_s})").rand rescue eval("#{value}.all.map(&:id)").rand)
            parameters_multiply(parameters_list, list_value)
          end
          (self.datatypes-done).each do |dt|
            list_value = parameters.dup
            list_value[:parameters] = parameters[:parameters].dup
            list_value[:parameters][k]=random_value(dt)
            parameters_multiply(parameters_list, list_value)
          end
        else
          v.each do |vc|
            list_value = parameters.dup
            list_value[:parameters] = parameters[:parameters].dup
            list_value[:parameters][k] = parameters[:parameters][k].dup
            list_value[:parameters][k]=vc ? vc.to_s : nil
            parameters_multiply(parameters_list, list_value)
          end
        end
      end
      parameters_list << parameters if flag==0
    end
    
    def self.evaluate_object(params)
      if params[:object]
        value = eval(params[:object].to_s.capitalize)
        params.merge!(value.all.rand.attributes)
        params.delete(:object)
      end
      params.each do |k, v|
        if v.instance_of?(Hash)
          evaluate_object(v)
        end
      end
    end
    
    def self.datatypes
      return [:boolean, :date, :datetime, :decimal, :float, :integer, :string, :nil, :blank]
    end
    
    def self.random_value(data_type)
      case data_type
      when :boolean
        Random.boolean
      when :date
        Random.date
      when :decimal
        Random.number(100000)
      when :integer
        Random.number(100000)
      when :float
        rand
      when :string
        Random.alphanumeric
      when :nil
        nil
      when :blank
        ""
      end
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