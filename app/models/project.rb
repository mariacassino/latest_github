class Project < ApplicationRecord
  
  def self.save_projects projects
    projects[1..10].each do |project|
      project_hash = project.as_json(only: ["name", "url", "stargazers_count"])
      new_record = Project.create
      new_record.update_columns(project_hash)
    end
  end
  
end