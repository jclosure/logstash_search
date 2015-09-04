# coding: utf-8
require 'slim'
require 'sinatra'
require 'stretcher'

configure do
  ES = Stretcher::Server.new('http://esbanl01.amd.com:9200')
end

class Logstash
  def self.match(index, message, size: 10000)
    ES.index(index).search size: size, query: {
      match: { message: message }
    }
  end
end

get "/" do
  redirect "/Exception"
end

get "/:word" do
  slim :index, locals: {
    entries: Logstash.match('logstash-*', params[:word])
  }
end

__END__
@@ layout
doctype html
html
  body== yield

@@ index
h1= "#{entries.total} entries matching “#{params[:word]}”"
ul
- entries.results.each do |entry|
    hr
    li= entry.message
    
