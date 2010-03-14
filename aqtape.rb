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

  current_class = 'rotw'
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
      #current_class = a[:class] = (current_class == 'new') ? 'new' : class_for(item)
      a[:mp3s] = []
      item.parent.search("b[text()*='MPEG Stream']").each do |m|
        # don't need to proxy w/ firefox
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

# play the tunes
get '/tunes/*' do 
  m = open("http://aquariusrecords.org/#{params[:splat]}", :content_length_proc => lambda{|l| headers('Content-Length' => l.to_s) })
  headers['Cache-Control'] = 'public; max-age=2592000'
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
