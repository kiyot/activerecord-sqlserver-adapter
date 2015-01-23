require 'cases/helper_sqlserver'


module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase

    # As far as I can tell, SQL Server does not support null bytes in strings.
    coerce_tests! :test_update_prepared_statement

  end
end




require 'models/topic'
class AttributeMethodsTest < ActiveRecord::TestCase

  coerce_tests! :test_typecast_attribute_from_select_to_false
  def test_typecast_attribute_from_select_to_false_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 2, 1, 0) as is_test").first
    assert !topic.is_test?
  end

  coerce_tests! :test_typecast_attribute_from_select_to_true
  def test_typecast_attribute_from_select_to_true_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 1, 1, 0) as is_test").first
    assert topic.is_test?
  end

end




class BasicsTest < ActiveRecord::TestCase

  coerce_tests! :test_column_names_are_escaped
  def test_column_names_are_escaped_coerced
    conn      = ActiveRecord::Base.connection
    classname = conn.class.name[/[^:]*$/]
    badchar   = "'"
    quoted = conn.quote_column_name "foo#{badchar}bar"
    assert_equal("#{badchar}foo#{badchar * 2}bar#{badchar}", quoted)
  end

end




class BelongsToAssociationsTest < ActiveRecord::TestCase

  # Since @client.firm is a single first/top, and we use FETCH the order clause is used.
  coerce_tests! :test_belongs_to_does_not_use_order_by

  coerce_tests! :test_belongs_to_with_primary_key_joins_on_correct_column
  def test_belongs_to_with_primary_key_joins_on_correct_column_coerced
    sql = Client.joins(:firm_with_primary_key).to_sql
    assert_no_match(/\[firm_with_primary_keys_companies\]\.\[id\]/, sql)
    assert_match(/\[firm_with_primary_keys_companies\]\.\[name\]/, sql)
  end

end




module ActiveRecord
  module ConnectionAdapters

    # Just like PostgreSQLAdapter does.
    TypeLookupTest.coerce_all_tests! if defined?(TypeLookupTest)

    # All sorts of errors due to how we test. Even setting ENV['RAILS_ENV'] to
    # a value of 'default_env' will still show tests failing. Just ignoring all
    # of them since we have no monkey in this circus.
    MergeAndResolveDefaultUrlConfigTest.coerce_all_tests! if defined?(MergeAndResolveDefaultUrlConfigTest)

  end
end




require 'models/post'
require 'models/subscriber'
class EachTest < ActiveRecord::TestCase

  coerce_tests! :test_find_in_batches_should_quote_batch_order
  def test_find_in_batches_should_quote_batch_order_coerced
    c = Post.connection
    assert_sql(/ORDER BY \[posts\]\.\[id\]/) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

end




require 'models/owner'
class Owner < ActiveRecord::Base
  scope :including_last_pet, -> {
    select('owners.*, (select TOP (1) p.pet_id from pets p where p.owner_id = owners.owner_id order by p.name desc ) as last_pet_id').
    includes(:last_pet)
  }
end
class EagerAssociationTest < ActiveRecord::TestCase

  # Use LEN() vs length() function.
  coerce_tests! :test_count_with_include
  def test_count_with_include_coerced
    assert_equal 3, authors(:david).posts_with_comments.where("LEN(comments.body) > 15").references(:comments).count
  end

  # Use TOP (1) in scope vs limit 1.
  coerce_tests! %r{including association based on sql condition and no database column}
  it "including association based on sql condition and no database column coerced" do
    assert_equal pets(:parrot), Owner.including_last_pet.first.last_pet
  end

end




require 'models/topic'
class FinderTest < ActiveRecord::TestCase

  coerce_tests! %r{doesn't have implicit ordering},
                :test_find_doesnt_have_implicit_ordering # We have implicit ordering, via FETCH.

  coerce_tests! :test_exists_does_not_select_columns_without_alias
  def test_exists_does_not_select_columns_without_alias_coerced
    assert_sql(/SELECT\s+1 AS one FROM \[topics\].*OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY/i) do
      Topic.exists?
    end
  end

  coerce_tests! :test_string_sanitation
  def test_string_sanitation_coerced
    assert_not_equal "'something ' 1=1'", ActiveRecord::Base.sanitize("something ' 1=1")
    assert_equal "N'something; select table'", ActiveRecord::Base.sanitize("something; select table")
  end

  coerce_tests! :test_take_and_first_and_last_with_integer_should_use_sql_limit
  def test_take_and_first_and_last_with_integer_should_use_sql_limit_coerced
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY/) { Topic.take(3).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY/) { Topic.first(2).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY/) { Topic.last(5).entries }
  end

end




require 'models/company'
class InheritanceTest < ActiveRecord::TestCase

  coerce_tests! :test_a_bad_type_column
  def test_a_bad_type_column_coerced
    Company.connection.with_identity_insert_enabled('companies') do
      Company.connection.insert "INSERT INTO companies (id, #{QUOTED_TYPE}, name) VALUES(100, 'bad_class!', 'Not happening')"
    end
    assert_raise(ActiveRecord::SubclassNotFound) { Company.find(100) }
  end

  coerce_tests! :test_eager_load_belongs_to_primary_key_quoting
  def test_eager_load_belongs_to_primary_key_quoting_coerced
    con = Account.connection
    assert_sql(/\[companies\]\.\[id\] IN \(1\)/) do
      Account.all.merge!(:includes => :firm).find(1)
    end
  end

end




module ActiveRecord
  class Migration
    class ChangeSchemaTest < ActiveRecord::TestCase

       # We test these.
      coerce_tests! :test_create_table_with_bigint,
                    :test_create_table_with_defaults

    end
  end
end




require 'models/developer'
require 'models/computer'
class NestedRelationScopingTest < ActiveRecord::TestCase

  coerce_tests! :test_merge_options
  def test_merge_options_coerced
    Developer.where('salary = 80000').scoping do
      Developer.limit(10).scoping do
        devs = Developer.all
        sql = devs.to_sql
        assert_match '(salary = 80000)', sql
        assert_match 'FETCH NEXT 10 ROWS ONLY', sql
      end
    end
  end

end




require 'models/topic'
module ActiveRecord
  class PredicateBuilderTest < ActiveRecord::TestCase

    coerce_tests! :test_registering_new_handlers
    def test_registering_new_handlers_coerced
      PredicateBuilder.register_handler(Regexp, proc do |column, value|
        Arel::Nodes::InfixOperation.new('~', column, Arel.sql(value.source))
      end)
      assert_match %r{\[topics\]\.\[title\] ~ rails}i, Topic.where(title: /rails/).to_sql
    end

  end
end




class RelationTest < ActiveRecord::TestCase

  coerce_tests! %r{doesn't have implicit ordering} # We have implicit ordering, via FETCH.

end




require 'models/post'
class SanitizeTest < ActiveRecord::TestCase

  coerce_tests! :test_sanitize_sql_like_example_use_case
  def test_sanitize_sql_like_example_use_case_coerced
    searchable_post = Class.new(Post) do
      def self.search(term)
        where("title LIKE ?", sanitize_sql_like(term, '!'))
      end
    end
    assert_sql(/\(title LIKE N''20!% !_reduction!_!!''\)/) do
      searchable_post.search("20% _reduction_!").to_a
    end
  end

end




require 'models/post'
module ActiveRecord
  class WhereChainTest < ActiveRecord::TestCase

    coerce_tests! :test_not_eq_with_array_parameter
    def test_not_eq_with_array_parameter_coerced
      expected = Arel::Nodes::Not.new("title = N'hello'")
      relation = Post.where.not(['title = ?', 'hello'])
      assert_equal([expected], relation.where_values)
    end

  end
end




require 'models/author'
class YamlSerializationTest < ActiveRecord::TestCase

  coerce_tests! :test_types_of_virtual_columns_are_not_changed_on_round_trip
  def test_types_of_virtual_columns_are_not_changed_on_round_trip_coerced
    author = Author.select('authors.*, 5 as posts_count').first
    dumped = YAML.load(YAML.dump(author))
    assert_equal 5, author.posts_count
    assert_equal 5, dumped.posts_count
  end

end

