# latest_github
Project for Adwerx; uses Github API to search for projects that were updated today and within a given set of parameters.

Live app- https://hidden-lake-68826.herokuapp.com/

Running locally:
- After cloning down, create `config/master.key` and place provided master key into it (no quotation marks necessary) to unlock env variables (Github, PostgreSQL) in `credentials.yml.enc`.*
- run `rails s` normally to view page running locally
- run `rake get:project_numbers` to print out to the console the number of projects within each increment of 200 stars; it’ll then invoke `rake get:projects` (or you can just skip to running `rake get:projects` to go straight to getting all the projects we want to save to the db).
- `rake get:projects` accumulates all the projects into an array & passes that to `rake save:all_projects` to save them to the db.


* Rails 5 has moved away from `application.yml` & now newly-generated apps come with `config/master.key` (plaintext, is NOT checked into version control) and `credentials.yml.enc` (encoded, CAN be checked into VC).
