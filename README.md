How to rapidly prototype with iron workers locally
====

One of the questions, we often get asked is how to develop with iron workers locally without having to continuously upload the workers.

In this blog post, we will explore the workflow for an application written in Ruby using the Rails framework.

The basic idea of developing with iron workers is that:

1. You should use a cloud hosted development database, such as the free <a href="https://postgres.heroku.com/blog/past/2012/4/26/heroku_postgres_development_plan/">Heroku Dev Database </a>. Please see below for instructions on how to set it up and how to use it with iron worker! It is important that you use a cloud hosted development database (instead of a local development database) because the workers are hosted on cloud and they need to be able to write back to a publicly accessable address.

2. You should package the workers up locally so that it operates fully functionally locally before uploading it to the cloud. This way we can ensure that we minimize the number of times that we have to upload the workers. Two things change when you package your workers up
  a. Your path changes; If you, for example, packages the model directory into the worker, the model will be at the root directory of the worker, in this case, you should change the load path in your local environment, so that we can micmick the file structure once you upload the worker
  b. Params, we will need to mock out params locally in order to micmick how the worker will receive payload in production

3. IronWorker is basically just a script that runs on a server. If you are able to mock out the difference in path and params, it will run exactly the same way locally or in production.


#### Example application
In this example application, we will use iron worker to implement a syntax highlighter

##### Snippet syntax highlighting
![Alt text](http://farm4.staticflickr.com/3803/9448026658_20dd60283f_o.png "Snippet syntax highlighting")
##### After syntax highlighting
![Alt text](http://farm4.staticflickr.com/3824/9448026648_041edee397_b.jpg "After syntax highlighting")


#### Before integrating iron workers

##### Original Snippet Controller code
```ruby
  def create
    @snippet = Snippet.new(snippet_params)
    if @snippet.save
      uri = URI.parse("http://pygments.appspot.com/")
      request = Net::HTTP.post_form(uri, lang: @snippet.language, code: @snippet.plain_code)
      @snippet.update_attribute(:highlighted_code, request.body)
      redirect_to @snippet
    else
      render :new
    end
  end

  private
  def snippet_params
    params.require(:snippet).permit(:language, :plain_code)
  end
```

In this example, the upon creating a snippet, the controller will make an api request to get syntax highlighting. And then the highlighted code will be saved into the database.

#### Develop a worker script that is fully functional locally.

workers/pygments/Pygments_worker.rb
```ruby
require_relative "./development/pygments_worker_dev.rb" unless ARGV.include?("-id")
require 'uri'
require 'net/http'
require 'pg'
require 'active_record'
require 'models/snippet'

def setup_database
  puts "Database connection details:#{params['database'].inspect}"
  return unless params['database']
  # estabilsh database connection
  ActiveRecord::Base.establish_connection(params['database'])
end

setup_database

uri = URI.parse("http://pygments.appspot.com/")
request = Net::HTTP.post_form(uri, lang: params["request"]["lang"], code: params["request"]["code"])

snippet = Snippet.where(:id => params["snippet_id"]).first
snippet.update_attribute(:highlighted_code, request.body)
```

workers/pygment/development/pygments_worker_dev.rb
```ruby
require 'yaml'
$LOAD_PATH.unshift(File.expand_path('../../../../app/', __FILE__))

def database_config
  YAML.load(File.open(File.expand_path('../../../../config/database.yml', __FILE__)))
end

def params
  {
    "database" => database_config["development"],
    "request" => {"lang" => "ruby", "code" => "def hello\n puts 'hello'\n end"},
    "snippet_id" => 1
  }
end
```

As you can see, Pygments_worker.rb is where the main logic lies, it connects to the database and it makes api calls to get the code snippets syntaxed highlighted and then write the result back into the database.

We suggest that you create a development folder within the folder where your worker is located and place a dev file in there. We will explain what each line does:

##### Step 1. Changing the path

```ruby
$LOAD_PATH.unshift(File.expand_path('../../../../app/', __FILE__))
```

This line changes the load path of ruby so that you can simply call
``` require "models/snippet" ```, instead of having to call ``` require_relative "../../../app/models/snippet" ```

This micmicks the folder structure of the worker. (Please see this on the directory structure of a worker)

##### Step 2. Mock out params (payload) that the workers will receive in production

```ruby
def database_config
  YAML.load(File.open(File.expand_path('../../../../config/database.yml', __FILE__)))
end

def params
  {
    "database" => database_config["development"],
    "request" => {"lang" => "ruby", "code" => "def hello\n puts 'hello'\n end"},
    "snippet_id" => 1
  }
end
```

These lines mock how the worker will receive its payload. The worker will receive its payload through the params method, very similar to how a sinatra/rails controller behaves. In order to test it locally, we will have to provide the params method so that we can see how it behaves. (Please see this <a href="http://stackoverflow.com/questions/17634684/modifying-predefined-params-var-in-sinatra-renders-it-nil">stackoverflow answer for why you should define params as a method instead of a variable</a>)


#### new controller code

```ruby
@client = IronWorkerNG::CLient.new(:token => "xxx", :project_id => "xxx")
@client.tasks.create("pygments",
                           "database" => Rails.configuration.database_configuration[Rails.env],
                           "request" => {"lang" => @snippet.language,
                                         "code" => @snippet.plain_code},
                           "snippet_id" => @snippet.id)
```

#### Step 3, Setting up your Heroku Dev Database

To Add heroku production database and dev database; Make sure you remember which one is for development

```
 heroku addons:add heroku-postgresql
 heroku addons:add heroku-postgresql:dev
```
To search for all your heroku databases
```
heroku config | grep postgresql
 => DATABASE_URL:                postgres://xxxxxxxxxxxxxxxx:xxxxxxxxxxxxxx@ec2-x4x-2xxx-xxx6-xx7.compute-1.amazonaws.com:5432/xxxx
 => HEROKU_POSTGRESQL_NAVY_URL:  postgres://xxxxxxxxxxxxxxxx:xxxxxxxxxxxxxx@c2-x4-225-xxx-227.compute-1.amazonaws.com:5432/xxxx
 => HEROKU_POSTGRESQL_WHITE_URL: postgres://xxxxxxxxxxxxxxxx:xxxxxxxxxxxxx-X9_@xxxxx-102-1xx.compute-1.amazonaws.com:5432/xxxxx
```
To Grab postgres database credentials
```
 heroku pg:credentials [YOUR_HEROKU_DEV_DATABASE_COLOR]
 => dbname=xxxxxxxx host=xxxxxxx.compute-1.amazonaws.com port=5432 user=xxxxxxxx password=xxxxxxxxxx-X9_ sslmode=require
```

Set up your **config/database.yml** to connect to the heroku dev database

```yml
development:
  adapter: postgresql
  encoding: unicode
  database: [dbname]
  pool: 5
  username: [user]
  password: [password]
  host: [host]
  sslmode: require
```

This line of code: ```  ActiveRecord::Base.establish_connection(params['database']) ```, takes the hash as parameters and estasblished connections with the database.

#### Deployment

Go to <a href="http://hud.iron.io">HUD</a> to down your iron.json credentials.

Use CLI
```
$ cd workers
$ iron_worker upload pygments
```

#### Lets analyse this line by line

``` $ cd workers ``` make sure that you in the directory that contains the iron.json file, as the CLI tool looks for iron.json for credentials

``` $ iron_worker upload pygments ``` it looks for a pygments.worker file in your current directory

In this post, we will explain the directory structure after you upload iron_worker and how to write a rake task for deployment
