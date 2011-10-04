module ActsAsQA
  def self.included(klass)
    klass.extend AAQA
  end 
  
  class Generate   
    
    # Creates a list of parameters
    def self.qa(params, repeat)
      parameters, path_list = {}, []
      params.each{|k, v| parameters[k.to_sym] = v}    
      parameters_multiply(path_list, parameters, repeat||1) #By default repeat is 1.
      path_list
    end
    
    # Generates a list of actions with different combinations of values for parameters.
    def self.parameters_multiply(path_list, parameters, repeat)
      count=0
      evaluate_object(parameters[:parameters]) 
      # Generates 'repeat' no of values for each variable parameters. So there will be '(repeat)^(no of variable parameters)' no of combinations.
      flag = self.multiply_all(count, path_list, parameters, repeat) unless count >= repeat
      path_list << parameters if flag==0
    end
    
    # Generates different values for parameters.
    # If a parameter is a symbol or an array then it will generate different values for parameters otherwise it will take the value of parameter as it is.
    def self.multiply_all(count, path_list, parameters, repeat)
      done, flag = [], 0
      Hash[[parameters[:parameters].select{|k, v| v.class==Symbol or v.class==Array}.first]].each do |k, v|
        flag=1
        v.class==Symbol ? self.multiply_if_symbol(count, path_list, parameters, repeat, k, v, flag, done) : self.generate_if_array(path_list, repeat, k,v,parameters)
      end
      flag
    end
    
    def self.multiply_if_symbol(count, path_list, parameters, repeat, k, v, flag, done)
      value = v.to_s.split('_').collect{|x| x.capitalize!}.join('')
      # Check if the parameter is a model name or a datatype and generates the random value.
      if self.datatypes.include?(v)
        done, count = self.generate_if_datatype(path_list, repeat, parameters, done, count, k, v)
      elsif (eval(value).descends_from_active_record? rescue false)
        count = self.generate_if_active_record(path_list, repeat, parameters, count, k, v, value)
      end
      done, count = self.generate_random(path_list, repeat, parameters,count, done, k, v)
    end
    
    def self.generate_if_datatype(path_list, repeat, parameters, done, count, k, v)
      list_value = parameters.dup
      list_value[:parameters] = parameters[:parameters].dup
      list_value[:parameters][k]=random_value(v)
      parameters_multiply(path_list, list_value, repeat)
      [done+[k], count+1]
    end
    
    def self.generate_if_active_record(path_list, repeat, parameters, count, k, v, value)
      list_value = parameters.dup
      list_value[:parameters] = parameters[:parameters].dup
      value = eval(value)
      list_value[:parameters][k]=(eval("#{value}.all.map(&:#{k.to_s})").rand rescue eval("#{value}.all.map(&:id)").rand)
      parameters_multiply(path_list, list_value, repeat)
      count+1
    end
    
    # Generates more random data based on the value of 'repeat'.
    def self.generate_random(path_list, repeat, parameters,count, done, k, v)
      (repeat-count).times do
        dt = (self.datatypes-done).rand
        done << dt
        list_value = parameters.dup
        list_value[:parameters] = parameters[:parameters].dup
        list_value[:parameters][k]=random_value(dt)
        count+=1
        parameters_multiply(path_list, list_value, repeat)
      end
      [done, count]
    end
    
    # If parameter is an array then it will use one by one the value of array as parameter value.
    def self.generate_if_array(path_list, repeat, k, v ,parameters)
      v.each do |vc|
        list_value = parameters.dup
        list_value[:parameters] = parameters[:parameters].dup
        list_value[:parameters][k] = parameters[:parameters][k].dup
        list_value[:parameters][k]=vc ? vc.to_s : nil
        parameters_multiply(path_list, list_value, repeat)
      end
    end
    
    # Evaluates the object. So if it's written ':object => :user' then it will find a random user and replace object with its attributes.
    # This way final result will be :id => 1, :name => 'Bob' ...
    def self.evaluate_object(params)
      if params[:object]
        value = eval(params[:object].to_s.capitalize)
        params.merge!(value.all.rand.attributes)
        params.delete(:object)
      end
      params.each{|k, v| evaluate_object(v) if v.instance_of?(Hash) }
    end
    
    # Different datatypes which can be used as value for a parameter.
    def self.datatypes
      return [:boolean, :datetime, :decimal, :float, :integer, :string, :nil, :blank]
    end
    
    # Generates random values based on datatype/
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
  end
  
  # Display the colored text.
  class Display
    def self.colorize(text, color_code) 
      "\e[#{color_code}m#{text}\e[0m"
    end
  end
  
  module AAQA    
    @@result = {}
    
    # Generates a routes file so that it can compare the routes with actual routes.
    def generate_routes_file
      home_directory = File.expand_path(".acts_as_qa", Rails.root)
      unless Dir.exists?(home_directory)
        status = Dir.mkdir('.acts_as_qa', 0777)
        status == 0 ? puts("Home Directory created") : puts("Home Directory could not be created.")
      else
        puts "Home directory exists."       
      end 
      filename = File.expand_path('routes.txt', "#{Rails.root}/.acts_as_qa")
      status=system("rake routes > #{filename}") ? puts('Routes Loaded') : puts("Something went wrong")
    end   

    # Fetch the list of all the controllers in the application.
    def fetch_controllers
      folder_name, controller_files = File.expand_path('controllers', "#{Rails.root}/app/"), []      
      inspect_directory(folder_name, controller_files)   
      controller_files.each_index{|i| controller_files[i]=controller_files[i].split('/controllers/').last}
      controller_files
    end
    
    def inspect_directory(folder_name, controller_files)
      directory = Dir.open(folder_name)
      directory.each do |file_name|        
        inspect_directory(file_name, controller_files) if File.directory?(file_name) && file_name != "." && file_name != ".."
        controller_files << folder_name+'/'+file_name if file_name.include?("_controller")
        inspect_directory(folder_name+"/"+file_name, controller_files) if File.directory?(folder_name+"/"+file_name) and file_name != '.' and file_name != '..'
      end
      controller_files
    end

    # Fetch all the QA parameters defined in the controller and generates the path.
    def fetch_controller_parameters
      generate_routes_file
      controller_files, paths_to_hit = fetch_controllers, []
      controller_files.each do |file_name|
        file, controller = File.expand_path(file_name, "#{Rails.root}/app/controllers"), file_name.split('_controller').first
        paths_to_hit+=read_file_and_find_paths(file, controller)
      end  # end of controller_files iterator
      paths_to_hit
    end # end of method  
    
    def read_file_and_find_paths(file, controller)
      paths_to_hit = []
      File.open(file, 'r') do |f|
        action=''
        while(line = f.gets)
          action = line.split('def').last.split(';').first.strip if line.include?('def')
          if line.include?('#QA')
            parameters, times = line.split('#QA ').last.strip.split('*')
            paths_to_hit << "qa({:controller => '#{controller}', :action => '#{action}', :parameters => {#{parameters}}}, #{times||@@repeat_global})" 
          end
        end # end of while
      end # end of file open
      paths_to_hit
    end

    # Finds the parameters and send the request and catch the request.
    def hit_path(root_url, repeat_global)
      @@repeat_global=repeat_global
      puts "please enter root_url (example: http://localhost)" and return unless root_url 
      paths_to_hit = fetch_controller_parameters
      paths_to_hit.each do |path|
        begin
          generate_parameters_and_hit_path(root_url, path)
        rescue Exception => e
          puts ActsAsQA::Display.colorize("Wrong parameters for #{path}. Error: #{e}", 31)
        end
      end # end of paths to hit
      show_result
    end
    
    def generate_parameters_and_hit_path(root_url, path)
      parameters_list = ActsAsQA::Generate.instance_eval path.chomp
      parameters_list.each do |parameters|
        validate_parameters_and_hit_path(parameters, root_url, path)
      end
    end
    
    def validate_parameters_and_hit_path(parameters, root_url, path)
      File.open("#{Rails.root}/.acts_as_qa/routes.txt", 'r') do |f|
        path_details = []
        while(line = f.gets)
          path_details << line if (line.include?(":controller=>\"#{parameters[:controller]}\"") && line.include?(":action=>\"#{parameters[:action]}\""))
        end # end of while
        if path_details.empty?
          display_error(path)
          next
        end
        hit_valid_paths(path_details, parameters, root_url, path)
      end# end of file open
    end
    
    def hit_valid_paths(path_details, parameters, root_url, path)
      path_details.each do |path_detail|
        path_specifications =  path_detail.split().inspect unless path_detail.blank?
        send_request(JSON.parse(path_specifications), parameters, root_url)
      end
    end
    
    # Send the request
    def send_request(specifications, parameters, root_url)
      puts "please enter root_url (example: http://localhost)" and return unless root_url
      method = (specifications.length <= 4 ? 'GET' : specifications[1])
      response, path, p = get_response(specifications, parameters, root_url, method)
      check_response(response)
    end
    
    def check_response(response)
      if(response.class.ancestors.include?(Net::HTTPOK) || response.class.ancestors.include?(Net::HTTPFound))
        request_add_to_result(parameters[:controller], parameters[:action], method, true)
        puts(ActsAsQA::Display.colorize("#{method}: #{path} [OK] if parameters are #{p}", 32))
      elsif(response.class.ancestors.include?(Net::HTTPNotFound))
        request_add_to_result(parameters[:controller], parameters[:action], method, true)
        puts(ActsAsQA::Display.colorize("#{method}: #{path} [NOTFOUND] if parameters are #{p}", 36))
      else
        request_add_to_result(parameters[:controller], parameters[:action], method, false)
        puts(ActsAsQA::Display.colorize("#{method}: #{path} [FAIL] FAILS WITH STATUS #{response.class}]  if parameters are #{p}", 31))
      end
    end
    
    def get_response(specifications, parameters, root_url, method)
      p = path = nil
      specifications.length <= 4 ? path = specifications[1] : path = specifications[2]
      p, data = (parameters[:parameters] || []), []
      p.each{|k,v| path.match(":#{k}") ? (path.gsub!(":#{k}", v.to_s)) : data << "#{k}=#{v}"}
      data, path = data.join('&'), path.split("(.:format")[0].gsub(/\(|\)/, '')
      uri = URI.parse("#{root_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port) 
      request = form_request(method, uri, p, data)
      response = http.request(request)
      [response, path, p]
    end
    
    def form_request(method, uri, p, data)
      case method
        when 'POST'
          request = Net::HTTP::Post.new(uri.path)
          request.set_form_data(p)
        when 'PUT'
          request = Net::HTTP::Put.new(uri.path)
          request.set_form_data(p)
        when 'GET'
          request = Net::HTTP::Get.new(uri.path+"?"+data)
        when 'DELETE'
          request = Net::HTTP::Delete.new(uri.path+"?"+data)
      end
      request
    end
    
    # creates no of requests, pass/fail result set for all paths.
    def request_add_to_result(controller, action, method, pass)
      if !@@result[controller]     
        @@result.merge!({controller => {action => {method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}}})
      elsif !@@result[controller][action]
        @@result[controller].merge!({action => {method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}})
      elsif !@@result[controller][action][method]
        @@result[controller][action].merge!({method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}) 
      else
        @@result[controller][action][method][:requests] += 1
        @@result[controller][action][method][pass ? :pass : :fail] += 1
      end
    end
    
    # Show the result.
    def show_result
      puts "-"*145+"\n Controller"+" "*40+"Action"+" "*24+"Method"+" "*14+"Total Requests"+" "*6+"Pass Requests"+" "*7+"Fail Requests\n"+"-"*145
      total=pass=fail=0
      @@result.each do |controller, x|
        x.each do |action, y|
          y.each do |method, z|
            total+=z[:requests]
            pass+=z[:pass]
            fail+=z[:fail]
            puts controller+" "*(50-controller.length)+action+" "*(30-action.length)+method+" "*(20-method.length)+z[:requests].to_s+" "*(20-z[:requests].to_s.length)+z[:pass].to_s+" "*(20-z[:pass].to_s.length)+z[:fail].to_s
          end
        end
      end
      puts "-"*145+"\n"+" "*100+total.to_s+" "*(20-total.to_s.length)+pass.to_s+" "*(20-pass.to_s.length)+fail.to_s+" "*(20-fail.to_s.length)+"\n"+"-"*145
    end
    
    # Error message if path doesn't exixt.
    def display_error(path)
       puts ActsAsQA::Display.colorize("PATH DOES NOT EXIST IN ROUTES #{path.inspect}", 31)
    end
  end
end