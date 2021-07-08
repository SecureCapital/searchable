# Searchable
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'searchable'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install searchable
```

## Testing Searchable

Pull the gem, and go to the root folder. MySQL database is needed and schema
dummy_test must be created. If your mysql installation has password set for
root user run:

```bash
$ export DUMMY_DATABASE_PASSWORD="you_password"
```

Set up data database, migrate and seed.

```bash
$ rails db:create RAILS_ENV=test
$ db:migrate RAILS_ENV=test
$ rails db:seed RAILS_ENV=test
```

Now testing can be done by running:

```bash
$ rails test
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
