class Project < ApplicationRecord
  
  def self.get_projects 
    # check env variables with `EDITOR=nano rails credentials:edit`
    github_token = Rails.application.credentials.dig(:github, :token)
    date = Date.today
    star_min = 0
    star_max = 0
    projects = []
    response = HTTParty.get("https://api.github.com/search/repositories?q=stars:1..2000+license:apache-2.0+fork:false+pushed:#{date}&per_page=100", headers: {"User-Agent" => "mariacassino", "Authorization" => "token #{github_token}"}) 
    absolute_count = response.parsed_response["total_count"]
    # Github api won't return more than 1000 results in a query, so I broke the requests up into increments of 0-20 stars for lower-starred projects and
    # 0-200 stars for higher-starred projects; there are too many projects <= 500 stars to paginate them all within the allotted 10 pages
    loop do 
      if star_max >= 200 
        star_max += 200
        star_min = star_max - 199
      else 
        star_max += 20
        star_min = star_max - 19
      end
      response = HTTParty.get("https://api.github.com/search/repositories?q=stars:#{star_min}..#{star_max}+license:apache-2.0+fork:false+pushed:#{date}&per_page=100", headers: {"User-Agent" => "mariacassino", "Authorization" => "token #{github_token}"}) 
      total_count = response.parsed_response["total_count"]
      # round up to account for pages that are only partially filled w/ results
      byebug if total_count.nil?
      total_pages = (total_count / 100.to_f).ceil
      page_counter = 0
      # loop iterates through each page in that star increment and pushes project into `projects` array
      loop do
        page_counter += 1
        response = HTTParty.get("https://api.github.com/search/repositories?q=stars:#{star_min}..#{star_max}+license:apache-2.0+fork:false+pushed:#{date}&per_page=100&page=#{page_counter}", headers: {"User-Agent" => "mariacassino", "Authorization" => "token #{github_token}"}) 
        projects << response.parsed_response["items"]
        break if page_counter == total_pages
      end
      break if star_max >= 2000
    end
    projects = projects.flatten
    save_projects(projects)
  end
  
  def self.save_projects projects
    projects.each do |project|
      project_hash = project.as_json(only: ["name", "url", "owner", "stargazers_count"])
      new_record = Project.create
      new_record.update_columns(project_hash)
    end
    byebug
    print "done"
  end
  
end