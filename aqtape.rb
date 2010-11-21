require 'rubygems'
require 'open-uri'
require 'sinatra'
require 'hpricot'

HIGHLIGHTS = "Highlights :"
ROTW = "Records of the Week :"
NEW_ARRIVALS = "Selected New Arrivals :"

get '/' do 

  doc = Hpricot(open("http://aquariusrecords.org/cat/newest.html"))
  @albums = []
  ids = []

  # hrpicot magic to parse the unbelievably rough html
  doc.search("b[text()*='MPEG Stream']:nth-of-type(3)").each do |item|
    a = {}
    a[:artist] = item.parent.search('b:first').text
    a[:album] = item.parent.search('em:first').text
    unless ids.include?(id = a[:artist] + '_' + a[:album])
      ids<<id 
      a[:description] = []
      item.parent.children.each do |e| 
        # keep from grabbing the end of the update after the last release
        break if e.inner_text =~ /---/
        # we only want text
        a[:description].push(e.to_s) if e.text? && e.inner_text =~ /\w+/
      end
      a[:description] = a[:description].join("<br />")
      a[:mp3s] = []
      item.parent.search("b[text()*='MPEG Stream']").each do |m|
        # typos in the list html can really cause problems
        next unless (m/('a')).first[:href] =~ /m3u/
        a[:mp3s]<< { :url => "/tunes#{((m/('a')).first[:href].gsub(/m3u/, 'mp3'))}", :name => (m/('a')).first.inner_text }
      end
      @albums<<a
    end
  end

  headers['Cache-Control'] = 'public, max-age=18000'
  erb :index
end

# play the tunes
get '/tunes/*' do 
  m = open("http://aquariusrecords.org/#{params[:splat]}", :content_length_proc => lambda{|l| headers('Content-Length' => l.to_s) })
  headers['Cache-Control'] = 'public, max-age=2592000'
  content_type 'audio/mpeg'
  m
end
