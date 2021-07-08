ENV["RAILS_ENV"] = "test"
FIXTURES_FOLDER = Rails.root.to_s+'/test/fixtures/'

# Clean up database
puts "######"
puts "CLEANING UP DATABASE!"

puts "Deleting records"
[Movie, Actor, Character, Rating].each do |klass|
  puts "Deleting #{klass.name}: #{klass.delete_all}"
  ActiveRecord::Base.connection.execute("ALTER TABLE `#{klass.table_name}` AUTO_INCREMENT = 1;")
end
puts "######"

puts "######"
puts "SEEDING DATABASE"

movies = YAML.load_file(FIXTURES_FOLDER+'movies.yml').values
Movie.create(movies)
puts "Created #{Movie.count} movies"

actors = YAML.load_file(FIXTURES_FOLDER+'actors.yml').values
Actor.create(actors)
puts "Created #{Actor.count} actors/actresses"

yml_characters = ERB.new(File.read(FIXTURES_FOLDER+'characters.yml.erb')).result
characters = YAML.load(yml_characters).values
Character.create(characters)
puts "Created #{Character.count} characters"

ratings = ERB.new(File.read(FIXTURES_FOLDER+'ratings.yml.erb')).result
ratings = YAML.load(ratings).values
Rating.create(ratings)
puts "Created #{Rating.count} ratings"

puts "######"
