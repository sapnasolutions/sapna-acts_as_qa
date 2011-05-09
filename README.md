Acts As QA
==========

Acts_as_qa checks all the actions defined in application and checks the response if it is success or some error.


Install as Gem
==============

Open your 'Gemfile' and add this line to the bottom:

    gem 'acts_as_qa'

Now run:
	
		bundle install


Install as Plugin
==============

To install as plugin run:
	
	rails plugin install git@github.com:sapnasolutions/sapna-acts_as_qa.git
		
Use
====

Now run the rake task

		rake acts_as_qa:setup
	
This will append parameters at the bottom of each controller for each controller. This rake task also creates a new environment 'acts_as_qa' and also add a before_filter in application_controller.rb so that user can be initialized. Now open each controller and modify parameters according to requirement of action.

format of the parameters:

		#QA :a => 'b'
		
for posts controller it will be:

		#QA :id => Post.first.id
		
Now open 'application_controller.rb' where you can see a filter set_current_user_for_qa where you can set your session for testing purpose.

Now open 'database.yml' and modify it according to your requirement. Note that this will delete/edit the record from database. So do not use a database which you don't want to modify.

Now start the server in 'acts_as_qa' environment. 
		
Now the application is ready to test. Run:

		rake acts_as_qa:hit[http://localhost:3000]
		
Now you can see the response from each actions.

Uninstall
===========

To uninstall run:

		rake acts_as_qa:remove
		
This task removes all the parameters added in controller, 'acts_as_qa' environment and the filter added in application_controller.rb
Now you can remove line the following line from 'Gemfile'

		gem 'acts_as_qa'
		
or you can remove the plugin from '/vendor/plugins/'


Note: This Gem/Plugin is compatible with rails 3.