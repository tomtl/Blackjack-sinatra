require 'rubygems'
require 'sinatra'

set :sessions, true

get '/form' do
  erb :form
end

get '/text' do
  "This is basic text"
end

get '/template' do
  erb :template_text
end

post '/myaction' do
  puts params['username']
end