# latest_github
Project for Adwerx; uses Github API to search for projects that were updated today and within a given set of parameters.

Live app- https://hidden-lake-68826.herokuapp.com/

Running locally:
- After cloning down, create `config/master.key` and place provided master key into it (no quotation marks necessary) to unlock env variables (Github, PostgreSQL) in `credentials.yml.enc`.**
- run `rails s` normally to view page running locally
- run `rake get:project_numbers` to print out to the console the number of projects within each increment of 200 stars; it’ll then invoke `rake get:projects` (or you can just skip to running `rake get:projects` to go straight to getting all the projects we want to save to the db).
- `rake get:projects` accumulates all the projects into an array & passes that to `rake save:all_projects` to save them to the db.


** Rails 5 has moved away from `application.yml` & now newly-generated apps come with `config/master.key` (plaintext, is NOT checked into version control) and `credentials.yml.enc` (encoded, CAN be checked into VC).


### Testing ideas-

- test ProjectsController
  - use `instance_variable_get` to check that instance variables are set correctly in `set_search_params` and `index` methods (including total project count and project count for each increment of 200 stars), and that all their correct values are available in `index`

- test `save:all_projects` rake task
  - set up tests for rake tasks at the top:
    - `require 'rake'`
    - `Rake::Task.clear`
    -  `LatestGithub::Application.load_tasks` or `Rails.application.load_tasks`
  - set up a fixture that’s an array of test projects, each with `:name`, `:url`, `:owner => {}`, `:login`, `:stargazers_count`, & an extra column (that should end up getting filtered out without error)
  - assign that array to a variable to pass into `Rake::Task["save:all_projects"].invoke()`
  - `expect(Project.count).to eq()` to check they were saved in the db
