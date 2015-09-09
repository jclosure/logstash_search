# coding: utf-8
require 'rubygems'

require 'bundler/setup'
Bundler.require(:default) 

require 'yaml'
require 'date'
require 'time'

environment = ARGV[0] || "dev"
hours =  (ARGV[1] || 1).to_f

# read in config from yaml file
config = YAML::load(IO.read('config_emailer.yml'))[environment]

$date_field_name = config['date_field']
$now = DateTime.now
$starting = ($now - (hours/24)).to_time.iso8601.to_s #ref: see notes
$ending = $now.to_time.iso8601.to_s


ES = Stretcher::Server.new(config['url'], {  
                             :read_timeout => 2000,
                             :open_timeout => 2000
                           })



class Logstash
  def self.match(index, message, size: 10000)
    ES.index(index).search size: size, query: {
      match: { message: message }
    }
  end
  def self.filter(params, size: 10000)

    #binding.pry
    # use an alias
    result = ES.index(params[:index]).search(

      # SNIP QUERY BEGIN
      
      "query": {
        "filtered": {
          "query": {
            "bool": {
              "should": [
                {
                  "query_string": {
                    "query": params[:word]
                  }
                }
              ]
            }
          },
          "filter": {
            "bool": {
              "must": [
               {
                  "range": {
                    "@timestamp": {
                      "from": params[:starting],
                      "to": params[:ending]
                    }
                  }
                }
              ]
            }
          }
        }
      },
      "size": params[:size],
      "sort": [
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        },
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        }
      ]

      # SNIP QUERY END
  
    )

    result
  end
end

# SEARCH
params = {
  :index => config['index'],
  :word => config['search'],
  :starting => $starting,
  :ending => $ending,
  :size => 10000
}

entries = Logstash.filter(params)

# LOCAL SORT
entries.results.sort! do |a,b|

  field_name = config['date_field']

  begin
    if a.key?(field_name) && b.key?(field_name) 
      DateTime.parse(a[field_name]) <=> DateTime.parse(b[field_name])
    else
      1
    end
  rescue => error
    puts "#{error.class} and #{error.message}"
    # start a REPL session
    #binding.pry
    1
  end
  
end

# DEFINE TEMPLATES
contents= %q(
doctype html
html
  head
    meta charset="UTF-8"
  body
    h1= "#{entries.total} entries matching “#{params[:word]}”"
    ul
      - entries.results.each do |entry|
        hr
        li= entry.message
)


# SEND EMAIL
results = { params: params, entries: entries }

html =  Slim::Template.new { contents }.render(results, results)


Pony.mail :to => config['to'],
          :from => config['from'],
          :subject => "#{params[:word]} in #{environment}",
          :html_body => html,
          :attachments => {"#{params[:word]}.html" => html},
          :via => :smtp,
          :via_options => {
            :address        => config['smtp_server'],
            :port           => '25',
            :enable_starttls_auto => false
            #:user_name      => 'user',
            #:password       => 'password',
            #:authentication => :plain, # :plain, :login, :cram_md5, no auth by default
            #:domain         => "amd.com" # the HELO domain provided by the client to the server
          }



