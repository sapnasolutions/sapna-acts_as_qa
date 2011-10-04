Acts As QA
==========

Acts_as_qa checks all the actions defined in the application and their responses. It returns success if response is success, redirect or 
page not found otherwise it returns false. 

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

Run the rake task

    rake acts_as_qa:setup
	
This will add parameters for each action in a controller. This rake task also creates a new environment 'acts_as_qa'. this task also adds a 
before_filter in application_controller.rb to create a logged in user. Open each controller and supply parameters according to requirement of 
action.

Formats of Parameters
=====================

Fallowing are the formats of the parameters:

    #QA :a => 'b'
    
so for show action for posts controller it will be:

    #QA :id => Post.first.id 
    
or

    #QA :id => :post
    
or 
    
    #QA :id => :integer
    
When a symbol is passed like :post or :integer, it automatically generates values for parameter. when the symbol is a name of model it first 
generates attribute of some random model instance. For Example if its :author_id => :post then it finds some random but existing author_id from 
Post Model and then it also generates some random integer, date string, float etc. By this way valid and invalid values can be passed to action 
which helps to test different type conditions. The possible datatypes are:

    :boolean
    :date
    :datetime
    :decimal
    :float
    :integer
    :string

When an array is passed in parameters it hits the action one by one using each value in array.

    #QA :name => ["foo", "bar"]

In the above example it will hit the action 2 times with :name => "foo" and :name => "bar". Similarly To test a action for user logged in and 
logged out add :user in parameters.

    #QA :user => [:user, :admin, nil]

so the values will be :user when normal user is logged in :admin when an administrator is logged in and nil when user is not logged in. 
To make this work add logic inside set_current_user_for_qa filter in application_controller.rb, generated by acts_as_qa. 
    
Add ':format' in parameters to test different formats of a action
    
    #QA :format => ['js', 'json', 'xml']
    
You can also add the number of times you want to hit the path in fallowing way:

    #QA :a => 'b', c => 'd' *3
    
Create Logged in user
======================

Now open 'application_controller.rb' where you can see a piece of code:

    #Generated by acts as qa
	  before_filter :set_current_user_for_qa

	  def set_current_user_for_qa
	    if Rails.env=='acts_as_qa'
	      #session[:user_id]=1
	    end
	  end
	
This filter will set a user session for the action. So you can modify this code accordingly to make user/admin login. Example:    

	  def set_current_user_for_qa
	    session[:user_id]=1 params[:user]=='admin'
    	session[:user_id]=2 params[:user]=='user'
	  end

Where :user_id should exist in database. Similarly if you are using devise gem for authentication you can add following line in the code:

    session["warden.user.user.key"] = ["User", [15], "$2a$10$RSVEtVgr4UGwwnbGNPn9se"]
    
Initialize Database
===================

WARNING : ActsAsQa can edit/delete/update records of database

As ActsAsQa can edit/delete/update records of database so you have two option

OPTION 1:

+	Take a dump of development datacase as acts_as_qa add/delete/update the records.
+	Run your server in development environment.
+	Run 'rake acts_as_qa:hit_paths[ROOT_URL,repeat]'
+	Copy back the old database.

OPTION 2: 

+	'rake acts_as_qa:setup' tack creates acts_as_qa environment and {YOUR_APP_NAME}_acts_as_qa database. Run rake db:migrate RATLS_ENV=acts_as_qa
+	Add Records to {YOUR_APP_NAME}_acts_as_qa database by coping data from fixtures or development database
+	Run your server in acts_as_qa environment
+	Run 'rake acts_as_qa:hit_paths[ROOT_URL,repeat]'
    
Where ROOT_URL can be http://localhost:3000 and repeat is a integer 1,2,3.... Which is no of times a action should be hit by ActsAsQa. If number 
of times to hit a action is already supplied in parametes (*3 or *4 in parameters) then it will overwrite the 'repete' for that action

Result
========

Response from each action has the following format:

    GET: /users/confirmation [OK] if parameters are {:id=>""}
    GET: /users/confirmation [OK] if parameters are {:id=>0.8721885707014159}
    GET: /users/confirmation [OK] if parameters are {:id=>true}
    GET: /crib_sheets [NOTFOUND] if parameters are {}
    GET: /crib_sheets/3 [NOTFOUND] if parameters are {:id=>3}
    GET: /crib_sheets/16542 [NOTFOUND] if parameters are {:id=>16542}
    GET: /crib_sheets/0.7283873076508682 [NOTFOUND] if parameters are {:id=>0.7283873076508682}
    GET: /crib_sheets/3 [NOTFOUND] if parameters are {:id=>3}
    GET: /crib_sheets/ [NOTFOUND] if parameters are {:id=>nil}
    GET: /crib_sheets/ [NOTFOUND] if parameters are {:id=>nil}
    GET: /dashboard.js [FAIL] FAILS WITH STATUS Net::HTTPUnauthorized]  if parameters are {:id=>0.4012952405196911, :format=>"js"}
    GET: /dashboard.js [FAIL] FAILS WITH STATUS Net::HTTPUnauthorized]  if parameters are {:id=>"J50h3RQQxVJmRBkw", :format=>"js"}
    GET: /dashboard.js [FAIL] FAILS WITH STATUS Net::HTTPUnauthorized]  if parameters are {:id=>false, :format=>"js"}
    GET: /dashboard.html [OK] if parameters are {:id=>0.14420009413931612, :format=>"html"}
    GET: /dashboard.html [OK] if parameters are {:id=>nil, :format=>"html"}
    GET: /dashboard.html [OK] if parameters are {:id=>false, :format=>"html"}
    GET: /about_us [OK] if parameters are {} 

Uninstall
===========

To uninstall first run:

    rake acts_as_qa:remove
    
This task removes all the parameters added in controller, 'acts_as_qa' environment and the filter added in application_controller.rb
Now you can remove the following line in 'Gemfile'

    gem 'acts_as_qa'
    
or you can remove the plugin from '/vendor/plugins/'

Note
======

Add necessary logic in set_current_user_for_qa filter if server is in development mode as set_current_user_for_qa is a before filter it will 
overwrite the user session. One solution is to pass :acts_as_qa => 'true' in parameters and set user session only if params[:acts_as_qa] is 
true. So filter will be....

	  def set_current_user_for_qa
	  	if params[:acts_as_qa]==true
	    	session[:user_id]=1 params[:user]=='admin'
        session[:user_id]=2 params[:user]=='user'
    	end
	  end