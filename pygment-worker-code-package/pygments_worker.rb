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

p snippet
