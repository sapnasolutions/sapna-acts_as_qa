Acts As QA
==========

Acts_as_qa checks all the actions defined in application and checks the response if it is success or not.

Requirement
============

Rails 3

Install as Gem
==============

Open your 'Gemfile' and add this line:

    gem 'acts_as_qa'

Now run:
	
		bundle install


Install as Plugin
=================

To install as plugin run:
	
	rails plugin install git@github.com:sapnasolutions/sapna-acts_as_qa.git
		
Getting started
===============

Now run the rake task

		rake acts_as_qa:setup
	
This will add parameters for each action in a controller. This rake task also creates a new environment 'acts_as_qa'. this tack also add a before_filter in application_controller.rb so that user can be initialized. Now open each controller and modify parameters according to requirement of action.

format of the parameters:

		#QA :a => 'b'
		
so for show action for posts controller it will be:

		#QA :id => Post.first.id 
		
or

		#QA :id => :post
		
or 
		
		#QA :id => :integer
		
When a symbol is passed like :post or :integer, it will automatically generate data. when the symbol is a name of model it will first generate attribute of some random model instance. Like if its :author_id => post then it will find some random author_id from Post. then it will also generate some random integer, date string, float etc. The possible datatypes are:

		:boolean
		:date
		:datetime
		:decimal
		:float
		:integer
		:string

To test a action logged in and logged out mode add :user in parameters.

		#QA :user => [:user, :admin, nil]
		
You can also add the number of times you want to hit the path in fallowing way:

		#QA :a => 'b', c => 'd' *3
		
By default it will hit the path only once.
		
Now open 'application_controller.rb' where you can see a piece of code:

		#Generated by acts as qa
	  before_filter :set_current_user_for_qa

	  def set_current_user_for_qa
	    if Rails.env=='acts_as_qa'
	      #session[:user_id]=1
	    end
	  end
	
This filter will set a user session for the action. So you can modify this code. Example:		

	  def set_current_user_for_qa
	    if Rails.env=='acts_as_qa'
	      session[:user_id]=1 if params[:user]=='admin'
				session[:user_id]=2 if params[:user]=='user'
	    end
	  end


Similarly if you are using devise gem for authentication you can add following line in the code:

		session["warden.user.user.key"] = ["User", [15], "$2a$10$RSVEtVgr4UGwwnbGNPn9se"]

Now start the server in 'acts_as_qa' environment and the the application is ready to test. Now you can test your application by Running:

		rake acts_as_qa:hit_paths[ROOT_URL]
		
Where ROOT_URL can be http://localhost:3000
		
Now you can see the response from each action.

Uninstall
===========

To uninstall first run:

		rake acts_as_qa:remove
		
This task removes all the parameters added in controller, 'acts_as_qa' environment and the filter added in application_controller.rb
Now you can remove the following line in 'Gemfile'

		gem 'acts_as_qa'
		
or you can remove the plugin from '/vendor/plugins/'

Note
===========

If you get following error while running 'acts_as_qa:setup'

	acts_as_qa database is not configured
	
Just try to run same task once again.
