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
dir '../app/models/'


full_remote_build true # Or remote

```

##### Upload to the cloud
```
cd workers
iron_worker upload pygments
```
```iron_worker upload [WORKER NAME]``` looks for an iron.json where you iron.io credentials should be stored. Therefore, if you stored your iron.json in your workers folder, you should first cd into that folder.
[WORKER NAME] is the file name of the .worker file - in this case pygments.worker


### IronCast 2:

##### Example worker file
```ruby
runtime "ruby"

# include postgresql and activerecord
gem "pg"
gem "activerecord"


exec "pygments_worker.rb"

# Merging models
dir '../app/models/'


remote
```

### IronCast 3:
##### Example Python Code
```python
def setup_env():
  for i in range(len(sys.argv)]:
    if sys.argv[i] == '-id':
      return
  # Do all your environment setup stuff here
```


##### Example Ruby Code

```ruby
require_relative "./development/pygments_worker_dev.rb" unless ARGV.include?("-id")

```

```ruby
$LOAD_PATH.unshift(File.expand_path('../../../app/', __FILE__))

def database_config
  YAML.load(File.open(File.expand_path('../../../config/database.yml', __FILE__)))
end

def params
  {
    "database" => database_config["development"],
    "request" => {"lang" => "ruby", "code" => "def hello\n puts 'hello'\n end"},
    "snippet_id" => 1
  }
end
```
