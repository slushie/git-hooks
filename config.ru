require 'sinatra'
require File.expand_path '../git-hooks.rb', __FILE__

run Sinatra::Application
