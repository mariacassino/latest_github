require 'httparty'
require 'byebug'
require File.expand_path('../../config/environment',  __FILE__)
require 'json'


Project.get_projects 
print Project.all.size
