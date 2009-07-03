require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'hpricot'

HIGHLIGHTS = "Highlights :"
ROTW = "Records of the Week :"
NEW_ARRIVALS = "Selected New Arrivals :"

get '/' do 

  doc = Hpricot(open("http://aquariusrecords.org/cat/newest.html"))
  @albums = []
  ids = []

  current_class = 'rotw'
  doc.search("b[text()*='MPEG Stream']:nth-of-type(3)").each do |item|
    a = {}
    a[:artist] = item.parent.search('b:first').text
    a[:album] = item.parent.search('em:first').text
    id = a[:artist] + '_' + a[:album]
    unless ids.include?(id)
      ids<<id 
      a[:description] = item.parent.children.select{|e| e.text? && e.inner_text =~ /\w+/ }.join
      #current_class = a[:class] = (current_class == 'new') ? 'new' : class_for(item)
      a[:mp3s] = []
      item.parent.search("b[text()*='MPEG Stream']").each do |m|
        if request.user_agent =~ /.*Firefox.*/
          a[:mp3s]<< { :url => "http://aquariusrecords.org#{((m/('a')).first[:href].gsub(/m3u/, 'mp3'))}", :name => (m/('a')).first.inner_text }
        else
          a[:mp3s]<< { :url => "/tunes#{((m/('a')).first[:href].gsub(/m3u/, 'mp3'))}", :name => (m/('a')).first.inner_text }
        end
      end
      @albums<<a
    end
  end

  erb :index
end

# TODO stream
get '/tunes/*' do 
  m = open("http://aquariusrecords.org/#{params[:splat]}", :progress_proc => lambda{|l| headers('Content-Length' => l.to_s) })
  content_type 'audio/mpeg'
  m
end

helpers do
  def class_for(element)
    if element.parent.preceding.at("[text()*='#{NEW_ARRIVALS}']")
      'new'
    elsif element.parent.preceding.at("[text()*='#{HIGHLIGHTS}']")
      'highlights'
    else
      'rotw'
    end
  end
end
