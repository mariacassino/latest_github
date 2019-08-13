# require 'rake'

# Rake::Task.clear
# LatestGithub::Application.load_tasks

class ProjectsController < ApplicationController

  def set_credentials
    @github_token = Rails.application.credentials.dig(:github, :token)
    @client_id = Rails.application.credentials.dig(:oauth, :client_id)
    @client_secret = Rails.application.credentials.dig(:oauth, :client_secret)
  end

  def set_search_params
    @repos_base = "https://api.github.com/search/repositories"
    @languages = "language:javascript+language:ruby"
    @licenses = "license:apache-2.0+license:gpl+license:lgpl+license:mit"
    @date = Date.today
    @headers = {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"}
  end

  def index
    set_credentials
    set_search_params
    response = HTTParty.get("#{@repos_base}?q=stars:1..2000+#{@languages}+#{@licenses}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
    @total_count = response.parsed_response["total_count"]
    star_min = 0
    star_max = 0
    loop do
      star_max += 200
      star_min = star_max - 199
      # Github search has custom rate limiting- only 30 requests per minute for authenticated or 10 requests for unauthenticated
      response = HTTParty.get("#{@repos_base}?q=stars:#{star_min}..#{star_max}+#{@languages}+#{@licenses}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
      project_count = response.parsed_response["total_count"]
      # puts "There are #{project_count} projects between #{star_min} and #{star_max} stars!"
      instance_variable_set("@_#{star_min}_to_#{star_max}".to_sym, project_count)
      break if star_max >= 2000
    end
    # Rake::Task["get:projects"].invoke
  end

end
