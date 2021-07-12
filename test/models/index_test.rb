require "test_helper"

class IndexTest < ActiveSupport::TestCase
  setup do
    @si = Searchable::Index.new(owner_id: 1, owner_type: 'User')
    @markdown = %Q(
      ### Heading

      <a>html</a>

      email@user.not

      number 12 lipsum øælweåâ

      ***

      *italic* **bold**

      gerald's house

      [google](https://www.google.com "Google's Homepage")
      [relative](/users)

      - list1
      - list 2
      - list 3
        - u1
        - u2

      | var1 | var2       | var3 |
      |------|:----------:|-----:|
      |navn  | 2018-01-01 |  500 |
      |navn2 | 2018-01-02 |  450 |
      |navn3 | 2018-01-03 | -150 |

      213.234%

      37.2

      -23.44

      ```ruby
      puts "Ruby code"
      ```
    )
  end

  test "can instantiate!" do
    puts "Can instantiate Searchable::Index"
    assert_instance_of Searchable::Index, @si
  end

  test "Can compress text" do
    puts "Can set compressed searchable text"
    @si.set_searchable_with(@markdown, compress: true)
    assert @si.searchable.is_a?(String)
    assert (@si.searchable =~ /.*italic.*/)==0
    assert (@si.searchable =~ /.*gerald's.*/)==0
    assert_nil @si.searchable =~ /#/

    @si.set_searchable_with(@markdown, strip_numbers: true)
    assert (@si.searchable =~ /.*2018-01-01.*/)==0
    assert (@si.searchable =~ /.*<\/a>/)==0

    @si.set_searchable_with(@markdown) do |compressed|
      'new_text'
    end
    assert @si.searchable == 'new_text'
  end

  test "Can set uncompressed text" do
    @si.searchable=@markdown
    assert @si.searchable.is_a?(String)
    assert @si.searchable =~ /#/
  end
end
