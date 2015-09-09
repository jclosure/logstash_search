# coding: utf-8
require 'yaml'
require 'slim'
require 'sinatra'
require 'stretcher'
require 'thin'
require 'pony'


# read in config from yaml file
config = YAML::load(IO.read('config.yml'))

environment = config['dev']

configure do
  ES = Stretcher::Server.new(environment['url'])
end

class Logstash
  def self.match(index, message, size: 10000)
    ES.index(index).search size: size, query: {
      match: { message: message }
    }
  end
end

get "/" do
  redirect "/*"
end

get "/:word" do
  word =  params[:word]
  html = slim :index, locals: {
                entries: Logstash.match('twitter', word)
              }
  logger.info html

  Pony.mail :to => 'joel.holder@amd.com',
            :from => 'joel.holder@amd.com',
            :subject => "#{word} in #{environment['name']}",
            :html_body => html,
            :attachments => {"#{word}.html" => html},
            :via => :smtp,
            :via_options => {
              :address        => 'txsmtp.amd.com',
              :port           => '25',
              :enable_starttls_auto => false
              #:user_name      => 'user',
              #:password       => 'password',
              #:authentication => :plain, # :plain, :login, :cram_md5, no auth by default
              #:domain         => "amd.com" # the HELO domain provided by the client to the server
            }
  
  return html
end

__END__
@@ layout
doctype html
html
  head
    meta charset="UTF-8"
  body== yield

@@ index
h1= "#{entries.total} entries matching “#{params[:word]}”"
ul
- entries.results.each do |entry|
    hr
    li= entry.message
    
