# coding: utf-8
require 'rubygems'

require 'bundler/setup'
Bundler.require(:default) 

require 'yaml'
require 'date'
require 'time'

require_relative 'extensions'
require_relative 'logstash'


class Emailer


  attr_accessor :config
  
  def initialize config
    @config = config

    @date_field_name = @config['date_field']
    @now = DateTime.now

    time_quotient = @config['time_quotient'].to_f

    @starting = (@now - time_quotient).to_time.iso8601.to_s #ref: see note
    @ending = @now.to_time.iso8601.to_s

    puts "start: #{@starting}"
    puts "end: #{@ending}"

    @es = Stretcher::Server.new(@config['url'], {  
                                  :read_timeout => 2000,
                                  :open_timeout => 2000
                                })
  end
  
  

  # SEARCH
  def search
    
    params = {
      :es => @es,
      :index => @config['index'],
      :word => @config['search'],
      :starting => @starting,
      :ending => @ending,
      :size => 10000
    }

    response = Logstash.query(params)
    
    puts "found: #{response.total} results"
    
    {
      config: @config,
      params: params,
      response: response
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

    if  response.total > 0
      input = { params: params, response: response }
      output[:html] = Slim::Template.new { template }.render(input, input)
    end

    output
  end

  def generate_csv output, fields
    response = output[:response]
    data = response.results.collect { |h| h.with(*fields) || h }.to_hashed_csv
    output[:data] = data
    output    
  end
  
  def send_email output

    html = output[:html]
    data = output[:data]
    word = output[:word]

    unless html.nil?
      Pony.mail :to => @config['to'],
                :from => @config['from'],
                :subject => "time period report: #{word} in #{@config['name']}",
                :html_body => html,
                #:attachments => {"#{@config['name']}.html" => html, "#{@config['name']}.csv" => data},
                :attachments => {"#{@config['name']}.csv" => data},
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
  end


  
  def self.run config
    emailer = self.new config
    output = emailer.search
    emailer.generate_csv output, config.fields
                         
    emailer.render output
    emailer.send_email output
    output
  end


  # self running class method
  def self.main(env = "dev",
                hours = 1.0,
                config_file = "config.yml")

    # initialize globals
    hours = hours.to_f 
    path_to_config = if File.file?(config_file)
                       config_file
                     end ||
                     if File.file?("../#{config_file}")
                       "../#{config_file}"
                     end
    
    # ensure config file
    if path_to_config.nil?
      raise 'no configuration file available...'
    end


    config = YAML::load(IO.read(path_to_config))[env]

    config['time_quotient'] = hours.to_f / 24

    config['fields'] = ["host","path","logdate","level","messagetext","category","contextId","thread","routeId","breadcrumbId"]

    self.run config
  end
  
end



