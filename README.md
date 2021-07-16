# Searchable
The purpose of searchable Rails plugin is to provide a direct Ruby implementation of indexing ActiveRecords as searchable. The indexation is highly configurable, easy to manage, and it is possible to let the index contain information of related data, making it easier for the user to find the needle in the haystack. On top of searchable a query interface is provided wrapping the awesome Rails querying features, making it simple to form queries of intermediate complexity. The QI has been build in order to DRY up controller index actions, providing a single line call for all the wherem ordering, tagging and search arguments.

**NOTICE!** inside the *extensions* folder the ruby classes Hash, Date, and DateInfinity are extended, this may impact your application. Do not use this gem before you understand the impact of the extensions to your application. Also, ensure to make tests when applying the query interface if you deliver restricted data, such that your test will indentify any data leak..

## Installation
Add to your Gemfile:

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

To allow for indexation run:

```bash
$ rails g searchable:install
$ rails db:migrate
```

## Usage
The gem is grouped into two `Searchable` and `Searchable::QueryInterface`, the former grants search methods and indexation of active records, the latter provides a wrapper of searchable and the rails query interface to generate rather sophisticated queries from JSON parameters and santation rules. The search indexations is stored in the model `Searchable::Index < ApplicationRecord` containing a searchable string in the column `searchable`; joining onto the index grants the ability to search on custom generated search strings per record. The usage is explained below; firstly the appliance in your ApplicationRecords, searching your models, sanitizing queries, and building query responses in your controllers.

### Indexation
Start by indexing the models, by adding to your code as:

```ruby
#/app/models/movie.rb
class Movie < ApplicationReord
  has_many :characters, :dependent => :destroy
  has_many :actors, :through => :characters
  has_many :ratings, :dependent => :delete_all

  include Searchable::Indexation
  index_as_searchable \
    watch_fields: [:title, :summary],
    save_async: true,
    touch_on_indexation: true,
    callbacks: [:actors, :characters]

  def generate_searchable
    [title, summary, characters.map(&:name), actors.map(&:name)]
  end
end
```

Including `Searchable::Indexation` should only be done along calling `index_as_searchable`. The method `index_as_searchable`, establishes a `has_one :searchable_index` relationship, and since the module `Indexation` only provides instance methods regarding the `searchable_index` the inclusion should always be in pair with the indexation. `index_as_searchable` takes following options:

| Option          | Type  | Description |
|-----------------|-------|-------------|
| `:watch_fields` | Array | Array of methods/fields on the model that are used in indexation. Changes to these should be watched for. When a watched field changes the searchable value (`searchable_index.searchable`) will be updated. Each field specified should have method like `saved_change_to_#{field}` in order to let searchable know tha re-indexation should take place. |
| `:save_async`   | Boolean | Whether to save `searchable_index` async after save or synchronously along save. Use the latency configuration to set the delay of indexation. Prefer async if the response to an update does not require sending the updated search string along the record. |
| `:touch_on_indexation` | Boolean | Whether or not an update on `searchable_index` should fire touch (i.e. update) on `updated_at` on its owner. |
| `:callbacks` | Array | Array of methods that also are indexed as searchable and relates to the model, and should be re-indexed after change. |

The method `generate_searchable` is provided in the `Indexation` module but it is recommended to override it with a custom implementation of what data tha should be stored into the searchable string. `generate_searchable` should return either an array of strings (nil is accepted) or a string. The afterwords parsing data into `Searchable::Index` is called with:

```ruby
# Searchable::Indexation
def set_searchable
  (searchable_index||build_searchable_index).set_searchable_with(
    generate_searchable,
    strip_fill_words: true,
    strip_duplicates: true,
    strip_numbers: true,
    strip_non_word_boundary: true,
    strip_special_characters: true
  )
end
```

`set_searchable` may be overridden to customize the compression behaviour on the string. If the generated value is rather large contains numbers, html, symbols etc. would probably want som compression, i.e. reduction of the string. Compression will obscure the contents from the original, which may offend users with a great memory, who will no longer be able to finde records with exact matches to the original string. Thus if searchable data is rather limited you might avoid compression. Providing `generate_searchable` method as above now saves movies with the names of the related characters and actors. The user may now search for a famous actor on movies and get a list of all movies featuring the actor. The `generate_searchable` method is manually linked to `watch_fields` such that a change on title or summary should re-index. The callbacks are set as to `:actors` and `:characters` when both models are `indexed_as_searchable`, and their generation includes data from the movie model. Omitting callbacks like this will leave the `Searchable::Index` inconsistent to the underlying data. To re-index all records run

```ruby
Movie.index_all_searchable
# Or to index all index all models async
Searchable::IndexWorker.perform_async(call: :index_klasses)
```
#### Take notice to touch_on_indexation

Setting `touch_on_indexation` to true will hit `updated_at` on your records when the searchable values changes. If Mark Hamil should change his name, all movies starring Mark Hamil will be re-indexed and its `updated_at` flag changed despite that the movie has not changed. Thus setting `touch_on_indexation` to `true` couples the searchable index close with the real data, and in that way its related data. You should not use `thouch_of_indexation` when it is crucial that your `updated_at` flag does not change when related data change.

### Searching
As a models has been indexed it can be searched, simply call:

```ruby
# Search for movies starring harrison, or titled 'star wars'
Movie.joins(:actors).search(title: 'star wars', 'actors.name': 'harrison').distinct.map(&:title)
  Movie Load (1.2ms)  SELECT DISTINCT `movies`.* FROM `movies` INNER JOIN `characters` ON `characters`.`movie_id` = `movies`.`id` INNER JOIN `actors` ON `actors`.`id` = `characters`.`actor_id` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE '%star%wars%') OR (actors.name COLLATE UTF8MB4_GENERAL_CI LIKE '%harrison%'))
=> ["Star Wars: Episode IV - A New Hope", "Indiana Jones and the Last Crusade", "Witness"]

# Search for movies titles 'star wars' and starring 'DiCaprio'
Movie.joins(:actors).search(title: 'star wars', 'actors.name': 'DiCaprio', join: 'AND').count(:all)
   (1.0ms)  SELECT COUNT(*) FROM `movies` INNER JOIN `characters` ON `characters`.`movie_id` = `movies`.`id` INNER JOIN `actors` ON `actors`.`id` = `characters`.`actor_id` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE '%star%wars%') AND (actors.name COLLATE UTF8MB4_GENERAL_CI LIKE '%DiCaprio%'))
=> 0

# Search for movies having searchable text like 'DiCaprio'
Movie.with_searchable.search(searchable: 'DiCaprio').map(&:searchable)
 Movie Load (0.5ms)  SELECT `movies`.*, `searchable_indices`.`searchable` as `searchable` FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%DiCaprio%'))
=> ["inception thief who steals corporate secrets through use dream-sharing technology given inverse task planting idea into mind ceo. cobb arthur ariande leonardo dicaprio joseph gordon-levit ellen page"]

# Search for movies having a tilte starting with star
Movie.search(title: 'star%', fuzzy: false).to_sql
=> "SELECT `movies`.* FROM `movies` WHERE ((title COLLATE UTF8MB4_GENERAL_CI LIKE 'star%'))"
```

To search a model without indexing it as searchable you may extend `Searchable::Indexation::ClassMethods`. The model `Searchable::Index` can be searched without beeing indexed:

```ruby
Searchable::Index.search(searchable: '%harrison ford%', fuzzy: false).pluck(:owner_type,:owner_id)
  (1.2ms)  SELECT `searchable_indices`.`owner_type`, `searchable_indices`.`owner_id` FROM `searchable_indices` WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%harrison ford%'))
=> [["Movie", 1], ["Movie", 2], ["Movie", 3], ["Actor", 1], ["Actor", 6], ["Actor", 7], ["Character", 1], ["Character", 4], ["Character", 7]]
```

This allows you to 'fuzzy' search all indexed models. The search methods takes following arguments:

| Argument       | Type    | Default | Description |
|----------------|---------|---------|-------------|
| `**kwargs`     | Hash    | {}      | Field search string mapping |
| `:join`        | String  | 'OR'    | 'OR'/'AND', value to join each argument with |
| ':fuzzy'       | Boolean | true    | When true, strings are prepended and appended with '%' and each space is replaced with '%', putting as many wildcards in the search as possible, otherwise no wildcards are added. |
| `:with_having` | Boolean | false   | Use having(...) rather then where(...) |

### The QueryInterface

The QueryInterface can be used in the controllers (or models) to build complex queries from JSON, i.e. request from an API-client or a HTML-form. The QueryInterface expects the to be called with a set of parameters from the client where each deep value is either a String, Hash, or Array - corresponding to JSON communication. The parameters are parsed through a set of sanitizers along a set of rules given by the application, returning a reduced Hash compatible to the `QueryInterface::Builder` which will produce the relevant SQL query and fetch the records. Only params and rules compatible to the QueryInterface will be accepted, thus knowing how to form queries and rules are essential.

#### Sanitation

```yml
changed_since:
  params:
    updated_at: date-time-string
  rules:
    NONE
  call:
    "where('updated_at > #{sanitized-date-time-string}')"
  description:
    "Shortcut to find all records updated since ..."

conditions:
  params:
    where:
      field_name: 'string / array of strings / range_start..range_end'
      ...
    where_not:
      ...
    or:
      ...
    or_not:
      ...
  rules:
    _filters:
      field_name:
        type: ':string/:integer/:numeric/:date/:datetime/:boolean'
        is_range: 'true/false'
        is_array: 'true/false'
      ...
    _allow_xor: 'true/false default true'
    _allow_xor_not: 'true/false default true'
  call:
    "where(params[:where]).where.not(params[:where_not]).or(model.where(params[:or]).where.not(params[:or_not]))"
  description:
    'Common where conditions. The user may only place conditions on fields given in the _filters rule. The sanitizer will try to convert the received values to the set type in the ruleset. Failure to convert will raise an exception. Unpermitted fields will be ignored and not raise an exception. If the user is not permitted to collect all records, which has been implemented with a where(...) query, it is essential to disallow `or` and `or_not` params as these will grant access to the unpermitted data.'

fields:
  params:
    fields: 'Array of srings'
  rules:
    _allowed_fields: 'Array of permitted fields to select'
    _required_fields: 'Array of fields that will be included disregarding the params.'
  call:
    select(fields)
  description:
    'Useful for reducing the amount of data or collecting associated data. Trying to fetch unpermitted fields do not raise an exception.'

order:
  params:
    order: "Hash of field names and ASC/DESC"
  rules:
    _allowed_ordering: "Array of fields that may be ordered on"

pagination:
  params:
    limit: 'integer > 0 AND <= _max_limit'
    page: 'integer > 0'
    offset: 'integer >= 0'
  rules:
    _max_limit: 'integer'
  call:
    limit(limit).offset(offset)
  description:
    'For restricting amount of records collected and server sided pagination. The user may set both offset and page, but one is sufficient.'

search:
  params:
    search:
      fuzzy: Boolean
      join: 'AND/OR'
      kwargs: "a set of fields and search strings"
  rules:
    _allow_search: "Boolean, ignore search or not"
    _allowed_search_fields: "Fields the user may query collate on"
    _default_search_field: "Field to replace :default, defaulted by searchable"
  call:
    'search(**kwargs, join: join, fuzzy: fuzzy)'
  description:
    "See searching above. Note that data is flat, thus field_names fuzzy, join, and with_having may never be searched!"

tagging:
  params:
    tags: 'Array of strings'
    on: 'String, Tagged on'
    any: 'Boolean, should match any of the tags, default true'
    match_all: 'Boolean, should match all tags'
    exclude: 'Boolean should exclude the tags'
  rules:
    _allowed_tags_on: 'Array of strings, "columens" that the user may search tags on'
  call:
    'tagged(...)'
  description:
    "See the gem acts as taggable"
```

Sanitation will raise errors when data cannot be converted to the expected, and sometimes when the user disobeys the rules. An exception tells the user that the query is incompatible, which is better than leaving the user in bliss and delivering unexpected data. By default is Sanitation nonrestrictive, but may be reconfigured.

To sanitize call:

```ruby
params = {
  fields: ['id','title','summary']
  where: {
    date: '2020-01-01..2020-12-31',
    type: ['Animation','Thriller'],
    pg13: true,
  },
  where_not: {
    ...
  },
  or: {
    ...
  },
  or_not: {
    ...
  },
  updated_at: '2020-01-01 00:00:00 UTC',
  order: {
    updated_at: 'desc',
  },
  search: {
    title: 'blood',
    summary: 'creepy',
    default: 'zombie',
    fuzzy: true,
    join: 'AND',
  },
  tags: ['horror','thriller'],
  on: 'genre',
  any: false,
  match_all: true,
  limit: 10,
  page: 2,

}
rules = {
  _allowed_fields: :any,
  _required_fields: [:type],
  _filters: {
    date: {type: :date, is_range: true},
    type: {type: :string, is_array: true},
    pg13: {type: :boolean},
  },
  _allow_xor: true,
  _allow_xor_not: true,
  _allow_search: true,
  _allowed_search_fields: :any,
  _default_search_field: :searchable,
  _allowed_ordering: :any,
  _allowed_tags_on: ['genre','type']
  _max_limit: 100,
}

Searchable::QueryInterface::Sanitizers.sanitize!(params, rules)
=> {...}
```

The rules should be exposed to the user, so he can form valid queries. Restrictions on fields, ordering, search fields etc. is useful to inform the user on what would work. Placing no restrictions allows the user to form queries on fields not available which may raise an exception.

#### ControllerMethods

To build a query from sanitized params one can `include Searchable::QueryInterface::ControllerMethods` and use the qi_build function. The function takes a chain, i.e. a model to query, params and compatible rules.

```ruby
class MoviesController < ApplicationController
  include Searchable::QueryInterface::ControllerMethods

  def rules
    {
      _allowed_fields: Movie.column_names+['searchable'],
      _filters: {
        id: {type: :integer, is_array: true},
        rental_price: {type: :numeric, is_range: true},
        updated_at: {type: :datetime, is_range: true},
        created_at: {type: :datetime, is_range: true},
      },
      _allowed_search_fields: ['title','summary','searchable'],
      _max_limit: 1000,
    }
  end

  def chain
    Movie.with_searchable
  end

  def index
    result = with_qi_rescue do
      qi_build(chain: chain, params: params.fetch(:q,{}).permit!, rules: rules)
    end
    if result.keys.include?(:error)
      render json: result, status: 400
    else
      result[:data] = result[:data].map(&:as_json)
      render json: result,
    end
  end
end
```

Now a request on the index action will form results like:

```ruby
get 'movies', {:q=>{:where=>{:rental_price=>"0..200"}, :search=>{:default=>"droid"}}}
=>
SELECT COUNT(*) FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%droid%')) AND `movies`.`rental_price` BETWEEN 0.0 AND 200.0
SELECT `movies`.*, `searchable_indices`.`searchable` as `searchable` FROM `movies` LEFT JOIN `searchable_indices` ON `searchable_indices`.`owner_id` = `movies`.`id` AND `searchable_indices`.`owner_type` = 'Movie' WHERE ((searchable COLLATE UTF8MB4_GENERAL_CI LIKE '%droid%')) AND `movies`.`rental_price` BETWEEN 0.0 AND 200.0 LIMIT 1000
{
  :data => [...]
  :count => 1,
  :limit => 1000,
  :page => 1,
  :offset => 0,
}
```

The results include pagination to let the user know how many times she should repeat the request to collect all results.


### Configuration
To configure searchable see `searchable.rb` and `searchable/query_interface.rb` for predefined options.

```ruby
# config/initializers/searchable.rb

Searchable.configure do |config|
  config.collate_function = "UTF8_BIN"
  coinfig.locale = "fr" # Database locale, what language data is written in
  fill_words_fr = %w(oui)
  searchable_limit = 65535 # use standard text limit on searchable_indices.searchbale
end

Searchable::QueryInterface.configure do |config|
  config.max_limit = 20
  config.sanitize_tagging = false # Ignore tagging altogether
  config.sanitize_fields = false # Do not let the user set fields
end
```

## Testing Searchable

Testing this gem is done in two: 1) a test of code not directly linked to a host application inside the `/test` folder, and 2) test of code heavily linked to a host application inside the `test/dummy/test` folder. To test the application run:

```bash
# /
$ rails test
```

To test in context of the a host application ensure your password to your root MySQL database is set in (or not if blank):

```yml
# `/_env_variables.yml`
DUMMY_DATABASE_PASSWORD: "you_password"
```

Go to `/test/dummy` and prepare the database and start testing:

```bash
# /test/dummy
$ rails db:drop RAILS_ENV=test
$ rails db:create RAILS_ENV=test
$ db:migrate RAILS_ENV=test
$ rails db:seed RAILS_ENV=test
$ rails test
```

Testing is all done whilst setting indexation synchronously; the `IndexWorker` has been tested but the async call instantiating it has not. Testing of the gem could in general be improved, so please do not hesitate to contribute!

## To come, when ready...

- Adding ActiveJob to accomodate none Sidekiq users
- Add worker abstraction switching between ActiveJob/Sidekiq
- Remove _xor bad naming on Conditions
- Add sanitized query to result_hash
- Test the touch functionality
- Ensure that any params not abiding the rules will raise an error
- Ensure implementation invariant to database
- Figure a way to resolve with_having
- Maybe remove extensions into searchable, and insantiate `Searchable::Date`, `Searchable::Hash` ...

## Contributing
Contact the author if you desire to contribute.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
