$LOAD_PATH << File.expand_path("../../lib",  __FILE__)
require 'test/unit'
require 'manage_meta'

class NoToS
end
NoToS.send( :undef_method, :to_s )

class NoInitializer
  undef_method :initialize if methods.include? :initialize
  include ManageMeta
end

class ManageMetaTest < Test::Unit::TestCase
  include ManageMeta
  
  # add refute methods for ruby 1.8.7
  if !self.instance_methods.include? :refute_respond_to
    def refute_respond_to(obj, func, msg = nil)
      assert ! obj.respond_to?( func, msg )
    end
    
    def refute(expr, msg = nil)
      assert ! expr, msg
    end
  end

  # test 'existence of add_meta method' do
  def test_methods_exist
    assert_respond_to self, :add_meta, "responds to add_meta()"
    assert_respond_to self, :del_meta, "responds to del_meta()"
    assert_respond_to self, :add_meta_format, "responds to add_meta_format()"
    assert_respond_to self, :render_meta, "responds to render_meta()"
    assert_respond_to self, :manage_meta_sym_to_name, "responds to manage_meta_sym_to_name()"
    assert_respond_to self, :manage_meta_name_to_sym, "responds to manage_meta_name_to_sym()"
  end
  
  def test_manage_meta_sym_to_name
    {:foo => 'Foo', :foo_bar => "Foo-Bar", :foo_bar_baz => "Foo-Bar-Baz", "Foo-Bar" => "Foo-Bar",
      "Foo_bar" => "Foo-Bar" }.each do |key, val|
      assert_equal manage_meta_sym_to_name(key), val, "manage_meta_sym_to_name(#{key}) == #{val}"
    end
  end
  
  def test_manage_meta_name_to_sym
    { 'Foo'  => :foo, 'Foo-Bar' => :foo_bar, 'Foo--Bar_Baz' => :foo_bar_baz,
      :foo_bar_baz => :foo_bar_baz, :foo____bar => :foo_bar }.each do |key, val|
      assert_equal manage_meta_name_to_sym(key), val, "manage_meta_name_to_sym(#{key}) == #{val}"
    end
  end

  def test_works_wo_initialize
    refute NoInitializer.methods.include?(:initialize), "NoInitializer does not have an initialize method"
    foo = nil
    assert_nothing_raised(Exception, "instantiating a class w/o an initialize method should work") do
      foo = NoInitializer.new
    end
    assert foo.instance_of?(NoInitializer), "foo is an instance of NoInitializer"
    refute foo.methods.include?(:initialize), "foo does not have an initialize method"
  end

  # add_meta tests
  # test "add_meta argument edge cases" do
  def test_add_meta_edge_cases

    assert_raise(ArgumentError, "name of meta must be present") { add_meta }
    assert_raise(ArgumentError, "value must be present") { add_meta :foo }
    assert_raise(ArgumentError, "value must not be nil") { add_meta :foo, nil }
    assert_raise(ArgumentError, "value must not be a hash") { add_meta :foo, :hash => true }

    # make sure fails if value does not respond to :to_s
    no_to_s = NoToS.new
    refute_respond_to no_to_s, :to_s, "no_to_s must not respond to 'to_s'"
    assert_raise(ArgumentError, "value must respond to to_s") { add_meta :no_to_s, no_to_s }
    
    assert_raise(RuntimeError, "illegal option must raise an error") { add_meta :foo, 'value', :bad_opt => 'stuff'}
  end
  
  # test "add_meta adds methods to meta_hash" do
  def test_add_meta_adds_meta
    assert_nothing_raised(Exception, "add_meta foo, bar is ok") { add_meta :foo, "bar" }
    assert self.instance_variable_get("@manage_meta_meta_hash").key?(:foo),
      "meta variable 'foo' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
    assert self.instance_variable_get("@manage_meta_meta_hash")[:foo] == 'bar',
      "meta variable 'foo' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
    assert_nothing_raised(Exception, "add_meta(bar) {'value'}") { add_meta( :bar ) { 'value' }}
    assert self.instance_variable_get("@manage_meta_meta_hash").key?(:bar),
      "meta variable 'bar' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
    assert self.instance_variable_get("@manage_meta_meta_hash")[:bar] == 'value',
      "meta variable 'bar' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
  end
  
  # test "add_meta concatenates value and output of block" do
  def test_add_meta_concats_value_and_block
    add_meta(:foo, 'arg value') { ' block value' }
    assert_equal self.instance_variable_get("@manage_meta_meta_hash")[:foo], 'arg value block value',
      "add meta must concatenate value of both arg value and output of block"
      add_meta(:foo, 'arg value', :format => :canonical) { ' block value' }
    assert_equal self.instance_variable_get("@manage_meta_meta_hash")[:foo], 'arg value block value',
      "add meta must concatenate value of both arg value and output of block with option present"
  end

  # test "add_meta with :format argument" do
  def test_add_meta_format_works
    # bad format option
    assert_raise(RuntimeError, "Must not accept undefined format") { add_meta :foo, 'value', :format => :bad_key }
    # good format options
    assert_nothing_raised("Must accept format arg as string") { add_meta :foo, 'value', :format => 'named' }
  end
  
  # test ' del_meta' do
  def test_del_meta_deletes_meta_tag
    assert_nothing_raised(Exception, "add_meta foo, bar is ok") { add_meta :foo, "bar" }
    assert self.instance_variable_get("@manage_meta_meta_hash").key?(:foo),
      "meta variable 'foo' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
    assert self.instance_variable_get("@manage_meta_meta_hash")[:foo] == 'bar',
      "meta variable 'foo' not defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
    del_meta(:foo)
    refute self.instance_variable_get("@manage_meta_meta_hash").key?(:foo),
      "meta variable 'foo' should not be defined #{self.instance_variable_get('@manage_meta_meta_hash')}"
  end
  
  # test 'add_meta_format' do
  def test_add_meta_format_adds_a_format
    format = '<meta foo-type="#{name}" content="#{content}"'
    add_meta_format(:foo, format)
    assert self.instance_variable_get("@manage_meta_format_hash").key?(:foo),
      "add_meta_format adds key to format_hash using symbol"
    assert self.instance_variable_get("@manage_meta_format_hash")[:foo] == format,
      "add_meta_format adds format properly"
    add_meta_format('bar', format)
    assert self.instance_variable_get("@manage_meta_format_hash").key?(:bar),
      "add_meta_format adds key to format_hash using string"
    assert self.instance_variable_get("@manage_meta_format_hash")[:bar] == format,
      "add_meta_format adds format properly"
  end
  
  # test 'render_meta' do
  def test_render_meta_renders_meta
    assert_match /name="Robots"/, render_meta, "render_meta contains robots meta tag"
    assert_match /name="Generator"/, render_meta, "render_meta contains generator meta tag" \
      if defined? Rails
    add_meta :foo, 'a value'
    assert_match /name="Foo"/, render_meta, "render_meta contains 'foo' meta tag"
    assert_match /content="a value"/, render_meta, "render_meta tag for foo has content 'a value'"
  end
  
end
