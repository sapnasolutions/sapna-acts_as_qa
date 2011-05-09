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
    
    def generate_routes_file
      generate_home 
      filename = File.expand_path('routes.txt', "#{Rails.root}/.acts_as_qa")
      if status = system("rake routes > #{filename}")
        puts 'Routes Loaded'
      else
        puts "Something went wrong"
      end
    end

    def generate_home
      home_directory = File.expand_path(".acts_as_qa", Rails.root)
      unless Dir.exists?(home_directory)
        status = Dir.mkdir('.acts_as_qa', 0777)
        if status == 0
          puts "Home Directory created"
        else
          puts "Home Directory could not be created."
        end 
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
            paths_to_hit << "qa({:controller => '#{controller}', :action => '#{action}', :parameters => {#{line.split('#QA ').last.strip}}})" if line.include?('#QA')
            #(eval(file_name.split('/').collect{|x| x.split('_').collect{|y| y.capitalize}.join('')}.join('::').split('.')[0]))
          end # end of while
        end # end of file open
      end  # end of controller_files iterator

      paths_to_hit
    end # end of method  

    def hit_path(root_url)
      p "please enter root_url (example: http://localhost)" and return unless root_url 
      paths_to_hit = fetch_controller_parameters
      paths_to_hit.each do |path|
        begin
          parameters = ActsAsQA::QAA.instance_eval path.chomp
          path_details = nil
          File.open("#{Rails.root}/.acts_as_qa/routes.txt", 'r') do |f|
            while(line = f.gets)
              path_details = line if (line.include?(":controller=>\"#{parameters[:controller]}\"") && line.include?(":action=>\"#{parameters[:action]}\""))
            end # end of while
            if path_details.blank?
              display_error(path)
              next
            end
            path_specifications =  path_details.split().inspect unless path_details.blank?
            send_request(JSON.parse(path_specifications), parameters, root_url)
          end# end of file open
        rescue Exception => e
          puts ActsAsQA::Display.colorize("Wrong parameters for #{path}. Error: #{e}", 31)
        end
      end # end of paths to hit
    end
    
    def send_request(specifications, parameters, root_url)
      p "please enter root_url (example: http://localhost)" and return unless root_url 
      p = path = nil
      specifications.length <= 4 ? path = specifications[1] : path = specifications[2]
      p = parameters[:parameters] || []
      p.delete(:action); p.delete(:controller )
      data = []
      p.each{|k,v| path.match(":#{k}") ? (path.gsub!(":#{k}", v.to_s) and p.delete(k)) : data << "#{k}=#{v}"}
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
      request.basic_auth 'admin@eduvee.com', 't34chm3'
      response = http.request(request)
      ok = (response.class.ancestors.include?(Net::HTTPOK) || response.class.ancestors.include?(Net::HTTPFound))
      puts(ok ? ActsAsQA::Display.colorize("#{method}: #{path} [OK]", 32) : ActsAsQA::Display.colorize("#{method}: #{path} [FAIL] FAILS WITH STATUS #{response.class}]", 31))
    end
    
    def display_error(path)
       puts ActsAsQA::Display.colorize("PATH DOES NOT EXIST IN ROUTES #{path.inspect}", 31)
    end
  end
  
end


def acts_as_qa
  controller_files = Dir.glob("#{Rails.root}/app/controllers/*_controller.rb")
  controller_classes = controller_files.collect{|file| file.split("/").last.split(".")[0].camelize.constantize }
  controller_classes.each do |klass|
    klass.send :include, ActsAsQA if klass != ApplicationController
  end
end


def test
  r = Rails.application.routes
  r.routes.first
end
