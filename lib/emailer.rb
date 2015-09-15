# coding: utf-8
require 'rubygems'

require 'bundler/setup'
Bundler.require(:default) 

require 'yaml'
require 'date'
require 'time'

require_relative 'extensions'


$environment = $environment || ARGV[0] || "dev"
$hours =  $hours || (ARGV[1] || 1).to_f
$path_to_config = $path_to_config || ARGV[2] || '../config.yml'

class Emailer

  def self.config
    YAML::load(IO.read($path_to_config))[$environment]
  end

  attr_accessor :config
  
  def initialize
    @config = Emailer.config

    @date_field_name = @config['date_field']
    @now = DateTime.now
    @starting = (@now - ($hours/24)).to_time.iso8601.to_s #ref: see note
    @ending = @now.to_time.iso8601.to_s

    puts "start: #{@starting}"
    puts "end: #{@ending}"


    
    @es = Stretcher::Server.new(@config['url'], {  
                                  :read_timeout => 2000,
                                  :open_timeout => 2000
                                })

    require_relative 'logstash'

  end
  
  

  # SEARCH
  def search

    # year_month = DateTime.parse(@ending).to_time.strftime("%Y.%m.*")
    # index_name = "logstash-#{year_month}"

    index_name = "#{config['index']}*"

    puts "searching index: #{index_name}"
    
    params = {
      :es => @es,
      :index => index_name,
      :word => @config['search'],
      :starting => @starting,
      :ending => @ending,
      :size => 10000
    }

    {
      params: params,
      response: Logstash.query(params)
    }

  end


  def render output

    params = output[:params]
    response = output[:response]

    
    template = %q(
doctype html
html
  head
    meta charset="UTF-8"
  body
    h1= "#{response.total} entries matching “#{params[:word]}”"
    ul
      - response.results.each do |result|
        hr
        li= result.message
)


    # SEND EMAIL
    puts "found: #{response.total} results"

    if  response.total > 0
      input = { params: params, response: response }
      output[:html] = Slim::Template.new { template }.render(input, input)
    end

    output[:html] = output[:html] || "no results"

    output
  end

  def generate_csv output
    response = output[:response]
    data = response.results.collect { |h| h.with("host","path","logdate","level","messagetext","category","contextId","thread","routeId", "breadcrumbId") || h }.to_hashed_csv
    output[:data] = data
    output    
  end
  
  def send_email output

    html = output[:html]
    data = output[:data]
    word = output[:word]


      Pony.mail :to => @config['to'],
                :from => @config['from'],
                :subject => "time period report: #{word} in #{$environment}",
                :html_body => html,
                :attachments => {"#{@config['name']}.html" => html, "#{@config['name']}.csv" => data},
                :via => :smtp,
                :via_options => {
                  :address        => @config['smtp_server'],
                  :port           => '25',
                  :enable_starttls_auto => false
                  #:user_name      => 'user',
                  #:password       => 'password',
                  #:authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                  #:domain         => "amd.com" # the HELO domain provided by the client to the server
                }
  end

  def run

    output = self.search
    self.generate_csv output
    self.render output
    self.send_email output
    output
    
  end
  
end

# self running for now
output = Emailer.new.run
