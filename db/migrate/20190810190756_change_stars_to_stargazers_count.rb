class ChangeStarsToStargazersCount < ActiveRecord::Migration[5.2]
  def up
    rename_column :projects, :stars, :stargazers_count
  end
  
  def down 
    rename_column :projects, :stargazers_count, :stars
  end
end
