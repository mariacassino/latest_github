require 'httparty'


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


namespace :get do
  desc "just get number of projects that meet all requirements and are within each star range"
  task :project_numbers => :environment do
    set_credentials
    set_search_params
    response = HTTParty.get("#{@repos_base}?q=stars:1..2000+#{@languages}+#{@licenses}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
    total_count = response.parsed_response["total_count"]
    puts "There should be #{total_count} projects that meet all parameters"
    star_min = 0
    star_max = 0
    loop do
      star_max += 200
      star_min = star_max - 199
      response = HTTParty.get("#{@repos_base}?q=stars:#{star_min}..#{star_max}+#{@languages}+#{@licenses}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
      project_count = response.parsed_response["total_count"]
      puts "There are #{project_count} projects between #{star_min} and #{star_max} stars!"
      break if star_max >= 2000
    end
    Rake::Task["get:projects"].invoke
  end
end


namespace :get do
  desc "get projects that meet certain requirements from Github's API"
  task :projects => :environment do
    set_credentials
    set_search_params
    projects = []
    response = HTTParty.get("#{@repos_base}?q=stars:1..2000+#{@languages}+#{@licenses}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
    all_projects_count = response.parsed_response["total_count"]
    # Github's API won't return more than 1000 results in a query (10 pages of results w/ 100 results per page, in this case),
    # so I broke the requests up into increments of pages to iterate through;
    # there are too many projects <= 5 stars to paginate them all within the allotted 10 pages, and a large portion of
    # licenses are MIT, so I broke the iteration down to MIT or every other license combined, then by star range, then by page.
    licenses = ["license:apache-2.0+license:gpl+license:lgpl", "license:mit"]
    licenses.each do |license|
      star_min = 0
      star_max = 0
      loop do
        # there are fewer higher-starred projects, so those can be iterated through in bigger increments
        if star_max >= 200
          star_max += 200
          star_min = star_max - 199
        # there are way more lower-starred projects, so those need to be iterated through in much smaller increments
        elsif star_max < 5
          star_max += 1
          star_min = star_max - 1
        else
          star_max += 5
          star_min = star_max - 4
        end
        break if star_max > 2000
        # sleep is needed here to slow down requests bc Github search has custom rate
        # limiting- only 30 requests per minute for authenticated or 10 requests for unauthenticated
        sleep 2
        star_range = "#{star_min}..#{star_max}"
        star_range = "#{star_max}" if star_max <= 5
        response = HTTParty.get("#{@repos_base}?q=stars:#{star_range}+#{@languages}+#{license}+fork:false+pushed:#{@date}&per_page=100?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
        sleep 1
        total_count = response.parsed_response["total_count"]
        next if total_count == 0
        # round up to account for pages that are only partially filled w/ results
        total_pages = (total_count / 100.to_f).ceil
        # puts "\n\n"
        puts "\n\n#{total_count} #{license} projects with #{star_range} stars, on #{total_pages} pages"
        page_counter = 0
        # loop iterates through each page in that star increment and pushes project into `projects` array
        loop do
          page_counter += 1
          sleep 2
          puts "Getting page #{page_counter}..."
          response = HTTParty.get("#{@repos_base}?q=stars:#{star_range}+#{@languages}+#{license}+fork:false+pushed:#{@date}&per_page=100&page=#{page_counter}?client_id=#{@client_id}&client_secret=#{@client_secret}", headers: @headers)
          projects << response.parsed_response["items"]
          break if page_counter == total_pages
        end
      end
    end
    projects = projects.flatten
    puts "#{projects.size} projects received from GET request"
    Rake::Task["save:all_projects"].invoke(projects)
  end
end


namespace :save do
  desc "add projects from Github API call to database"
  task :all_projects, [:projects] => :environment do |task, args|
    puts "adding projects to database..."
    args["projects"].each do |project|
      project_hash = project.as_json(only: ["name", "url", "owner", "login", "stargazers_count"])
      new_record = Project.create(name: project_hash["name"], url: project_hash["url"], owner: project_hash["owner"]["login"], stargazers_count: project_hash["stargazers_count"] )
    end
    puts "done!"
    puts "Projects in database: #{Project.all.size}"
  end
end
