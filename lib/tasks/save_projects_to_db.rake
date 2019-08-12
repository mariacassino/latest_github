require 'httparty'

def set_credentials 
  @github_token = Rails.application.credentials.dig(:github, :token)
  @client_id = Rails.application.credentials.dig(:oauth, :client_id)
  @client_secret = Rails.application.credentials.dig(:oauth, :client_secret)
end


namespace :get do 
  desc "just get number of projects that meet all requirements and are within each star range"
  task :project_numbers => :environment do 
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
    Rake::Task["get:projects"].invoke
  end
end 


namespace :get do 
  desc "get projects that meet certain requirements from Github's API"
  task :projects => :environment do 
    byebug
    set_credentials
    date = Date.today
    star_min = 0
    star_max = 0
    projects = []
    response = HTTParty.get("https://api.github.com/search/repositories?q=stars:1..2000+language:javascript+language:ruby+license:apache-2.0+license:gpl+license:lgpl+license:mit+fork:false+pushed:#{date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"})
    all_projects_count = response.parsed_response["total_count"]
    # Github api won't return more than 1000 results in a query, so I broke the requests up into increments of 0-20 stars for lower-starred projects and
    # 0-200 stars for higher-starred projects; there are too many projects <= 500 stars to paginate them all within the allotted 10 pages
    loop do 
      if star_max >= 200 
        star_max += 200
        star_min = star_max - 199
      else 
        star_max += 5
        star_min = star_max - 4
      end
      # Github search has custom rate limiting- only 30 requests per minute for authenticated or 10 requests for unauthenticated
      sleep 2
      response = HTTParty.get("https://api.github.com/search/repositories?q=stars:#{star_min}..#{star_max}+language:javascript+language:ruby+license:apache-2.0+license:gpl+license:lgpl+license:mit+fork:false+pushed:#{date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"}) 
      total_count = response.parsed_response["total_count"]
      # round up to account for pages that are only partially filled w/ results
      total_pages = (total_count / 100.to_f).ceil
      byebug if total_pages > 10
      page_counter = 0
      # loop iterates through each page in that star increment and pushes project into `projects` array
      loop do
        page_counter += 1
        sleep 2
        response = HTTParty.get("https://api.github.com/search/repositories?q=stars:#{star_min}..#{star_max}+license:apache-2.0+language:javascript+language:ruby+license:gpl+license:lgpl+license:mit+fork:false+pushed:#{date}&per_page=100&page=#{page_counter}?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: {"User-Agent" => "latest_github", "Authorization" => "token #{@github_token}"}) 
        projects << response.parsed_response["items"]
        break if page_counter == total_pages
      end
      break if star_max >= 2000
    end
    projects = projects.flatten
    puts "#{projects.size} projects received from GET request"
    Rake::Task["save:all_projects"].invoke(projects)
  end
end 


namespace :save do
  desc "add projects from Github API call to database"
  task :all_projects, [:projects] => :environment do |task, args|
    projects.each do |project|
      project_hash = project.as_json(only: ["name", "url", "owner", "login", "stargazers_count"])
      new_record = Project.create(name: project_hash["name"], url: project_hash["url"], owner: project_hash["owner"]["login"], stargazers_count: project_hash["stargazers_count"] )
    end
    puts "done"
    puts "Total added: #{Project.all.size}"
  end
end