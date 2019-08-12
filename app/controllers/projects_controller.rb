class ProjectsController < ApplicationController
  
  def show 
    byebug
  end
  
  def set_credentials 
    @github_token = Rails.application.credentials.dig(:github, :token)
    @client_id = Rails.application.credentials.dig(:oauth, :client_id)
    @client_secret = Rails.application.credentials.dig(:oauth, :client_secret)
  end
  
  def index 
    set_credentials
    date = Date.today
    response = HTTParty.get("https://api.github.com/search/repositories?q=stars:1..2000+language:javascript+language:ruby+license:apache-2.0+license:gpl+license:lgpl+license:mit+fork:false+pushed:#{date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"}) 
    total_count = response.parsed_response["total_count"]
    puts "There should be #{total_count} projects that meet all parameters"
    star_min = 0
    star_max = 0
    loop do 
      star_max += 200
      star_min = star_max - 199
      # Github search has custom rate limiting- only 30 requests per minute for authenticated or 10 requests for unauthenticated
      response = HTTParty.get("https://api.github.com/search/repositories?q=stars:#{star_min}..#{star_max}+language:javascript+language:ruby+license:apache-2.0+license:gpl+license:lgpl+license:mit+fork:false+pushed:#{date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"}) 
      project_count = response.parsed_response["total_count"]
      byebug if project_count.nil?
      puts "There are #{project_count} projects between #{star_min} and #{star_max} stars!"
      instance_variable_set("@_#{star_min}_to_#{star_max}".to_sym, project_count)
      break if star_max >= 2000
    end
    # Rake::Task["get:projects"].invoke
  end

end
