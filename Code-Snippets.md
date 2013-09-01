Code Snippets for IronCast 1-4
==============================

### IronCast 1:

##### Writing the Controller Code to queue up a job on IronWorker to be done asynchronously

```ruby
class SnippetsController < ApplicationController

  def create
    @snippet = Snippet.new(snippet_params)
    if @snippet.save
      @client ||= IronWorkerNG::Client.new(:token => ENV["TOKEN"], :project_id => ENV["PROJECT_ID"])
      @client.tasks.create("pygments",
                           "database" => Rails.configuration.database_configuration[Rails.env], # This sends in database credentials
                           "request" => {"lang" => @snippet.language,
                                         "code" => @snippet.plain_code},
                           "snippet_id" => @snippet.id)
      redirect_to @snippet
    else
      render :new
    end
  end

```

##### Writing the worker script to make the API request and save back to the database

```ruby
setup_database

uri = URI.parse("http://pygments.appspot.com/")
request = Net::HTTP.post_form(uri, lang: params["request"]["lang"], code: params["request"]["code"])

snippet = Snippet.where(:id => params["snippet_id"]).first
snippet.update_attribute(:highlighted_code, request.body)
```

```ruby 
def setup_database
  puts "Database connection details:#{params['database'].inspect}"
  return unless params['database']
  # estabilsh database connection
  ActiveRecord::Base.establish_connection(params['database'])
end
```

##### Writing the worker file to declare dependencies of this worker

```ruby
runtime "ruby"

# include postgresql and activerecord
gem "pg"
gem "activerecord"


exec "pygments_worker.rb"

# Merging models
dir '../app/models/', "app"


full_remote_build true # Or remote

```

##### Upload to the cloud
```
cd workers
iron_worker upload pygments 
```
iron_worker upload You must be in the directory where iron.json (Your iron.io credentials) is located
(file name of the .worker file - in this case pygments.worker)
