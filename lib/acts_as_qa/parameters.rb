module ActsAsQA
  def self.included(klass)
    klass.extend ClassMethods


    klass.class_eval do
      skip_before_filter :verify_authenticity_token
      puts "eval done"
    end

    filters = klass._process_action_callbacks.select{|c| c.kind == :before}
    filters.each {|f| puts "active filters #{f.filter}"}
   end 
  

  module ClassMethods    
    
    @@result = {}
    
    def generate_routes_file
      generate_home 
      filename = File.expand_path('routes.txt', "#{Rails.root}/.acts_as_qa")
      status=system("rake routes > #{filename}") ? puts('Routes Loaded') : puts("Something went wrong")
    end

    def generate_home
      home_directory = File.expand_path(".acts_as_qa", Rails.root)
      unless Dir.exists?(home_directory)
        status = Dir.mkdir('.acts_as_qa', 0777)
        status == 0 ? puts("Home Directory created") : puts("Home Directory could not be created.")
      else
        puts "Home directory exists."       
      end
    end      

    def fetch_controllers
      folder_name = File.expand_path('controllers', "#{Rails.root}/app/")      
      controller_files = []
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

    def fetch_controller_parameters
      generate_routes_file
      controller_files = fetch_controllers
      
      paths_to_hit = []
      controller_files.each do |file_name|
        file = File.expand_path(file_name, "#{Rails.root}/app/controllers")
        controller = file_name.split('_controller').first
        File.open(file, 'r') do |f|
          action=''
          while(line = f.gets)
            action = line.split('def').last.split(';').first.strip if line.include?('def')
            if line.include?('#QA')
              parameters = line.split('#QA ').last.strip
              paths_to_hit << "qa({:controller => '#{controller}', :action => '#{action}', :parameters => {#{parameters}}})" 
            end
            #(eval(file_name.split('/').collect{|x| x.split('_').collect{|y| y.capitalize}.join('')}.join('::').split('.')[0]))
          end # end of while
        end # end of file open
      end  # end of controller_files iterator

      paths_to_hit
    end # end of method  

    def hit_path(root_url)
      puts "please enter root_url (example: http://localhost)" and return unless root_url 
      paths_to_hit = fetch_controller_parameters
      paths_to_hit.each do |path|
        begin
          parameters_list = ActsAsQA::QAA.instance_eval path.chomp
          parameters_list.each do |parameters|
            path_details = nil
            File.open("#{Rails.root}/.acts_as_qa/routes.txt", 'r') do |f|
              path_details = []
              while(line = f.gets)
                path_details << line if (line.include?(":controller=>\"#{parameters[:controller]}\"") && line.include?(":action=>\"#{parameters[:action]}\""))
              end # end of while
              if path_details.empty?
                display_error(path)
                next
              end
              path_details.each do |path_detail|
                path_specifications =  path_detail.split().inspect unless path_detail.blank?
                send_request(JSON.parse(path_specifications), parameters, root_url)
              end
            end# end of file open
          end
        rescue Exception => e
                          puts ActsAsQA::Display.colorize("Wrong parameters for #{path}. Error: #{e}", 31)
                        end
      end # end of paths to hit
      show_result
    end
    
    def send_request(specifications, parameters, root_url)
      puts "please enter root_url (example: http://localhost)" and return unless root_url 
      p = path = nil
      specifications.length <= 4 ? path = specifications[1] : path = specifications[2]
      p = parameters[:parameters] || []
      data = []
      p.each{|k,v| path.match(":#{k}") ? (path.gsub!(":#{k}", v.to_s)) : data << "#{k}=#{v}"}
      data = data.join('&')
      path = path.split("(.:format")[0]
      path.gsub!(/\(|\)/, '')
      uri = URI.parse("#{root_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port) 
      method = (specifications.length <= 4 ? 'GET' : specifications[1])
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
      response = http.request(request)
      ok = (response.class.ancestors.include?(Net::HTTPOK) || response.class.ancestors.include?(Net::HTTPFound))
      if ok
        request_add_to_result(parameters[:controller], parameters[:action], method, true)
        puts(ActsAsQA::Display.colorize("#{method}: #{path} [OK] if parameters are #{p}", 32))
      else
        request_add_to_result(parameters[:controller], parameters[:action], method, false)
        puts(ActsAsQA::Display.colorize("#{method}: #{path} [FAIL] FAILS WITH STATUS #{response.class}]  if parameters are #{p}", 31))
      end
    end
    
    def request_add_to_result(controller, action, method, pass)    
      unless @@result[controller]     
        @@result.merge!({controller => {action => {method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}}})
      else
        unless @@result[controller][action]
          @@result[controller].merge!({action => {method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}})
        else
          unless @@result[controller][action][method]
            @@result[controller][action].merge!({method => {:requests => 1, :pass => (pass ? 1 : 0), :fail => (pass ? 0 : 1)}}) 
          else
            @@result[controller][action][method][:requests] += 1
            pass ? @@result[controller][action][method][:pass] += 1 : @@result[controller][action][method][:fail] += 1
          end
        end
      end
    end
    
    def show_result
      puts "-"*145
      puts "Controller"+" "*40+"Action"+" "*24+"Method"+" "*14+"Total Requests"+" "*6+"Pass Requests"+" "*7+"Fail Requests"
      puts "-"*145
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
      puts "-"*145
      puts " "*100+total.to_s+" "*(20-total.to_s.length)+pass.to_s+" "*(20-pass.to_s.length)+fail.to_s+" "*(20-fail.to_s.length)
      puts "-"*145
    end
    
    def display_error(path)
       puts ActsAsQA::Display.colorize("PATH DOES NOT EXIST IN ROUTES #{path.inspect}", 31)
    end
  end
end