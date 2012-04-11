ManageMeta
============

ManageMeta is yet another meta tag manager for Rails 3.x. Its features
are: recognizes tags should render as HTTP-EQUIV; supports the Google
'canonical' link; is extensible; is non-intrusive

NOTE: ManageMeta works by `include`ing itself into
ActionController::Base via an `initializer` which is enclosed in
ManageMeta::Railtie. This works for Rails 3.0.x and 3.1.x. Don't know
if it works in Rails 2.x

What's New in Release 0.0.13?
------------

Support for Facebook Open Graph.

It's a bit clunky, but it will work and can be used to use ManageMeta
as a prerequisite for an Open Graph metadata handling module. I may do
that 'one of these days', but until then, see sketch below.

How to use it
-----------

Include the gem by adding this to your Gemfile file

`gem "manage_meta", ">=0.0.13"`

or

`gem "manage_meta", :git => "git://github.com/mikehoward/manage_meta.git"`

Then, in your controller actions, call *add_meta()* for each meta tag
you want to define.

`add_meta :author, 'Fred Fink'`

If there are meta tags you don't want to define, you can use
*del_meta()* to remove them.  At present there are only two
automatically defined: 'robots' and 'generator'. You may also redefine
them by using *add_meta()* to give them new values.

If there is a meta tag which requires a currently unsupported format,
you may add the format using *add_meta_format()*, and then add the tag
using *add_meta()*.

Finally, edit app/views/layouts/application.html.erb - or equivalent - to insert

`<%= render_meta %>`

into the _head_ section of your HTML output. This will render and
return all of the defined meta tags.

NOTE: `manage_meta` now creates `charset` meta tags for HTML5 and (if
desired) HTML4.01 and XHTML output. These tags should be placed early
in the <head> section of your page.

`manage_meta` does this by inserting the appropriate meta tag at the
head of the rendered metadata. Consequently, you should put the `<%=
render_meta %>` statement IMMEDIATELY after the <head> tag if (1) your
document is an HTML5 OR (2) it is HTML 4 or XHTML and you
`add_meta(:content_type, ...)`.

What it Adds
------------

ManageMeta defines seven (9) methods and three (6) instance variables
into all classes derived from ApplicationController

The public methods are:

* `add_meta()` - adds a meta tag
* `del_meta()` - which deletes a meta tag
* `add_meta_format()` - which adds a meta tag format
* `render_meta()` - which returns a string rendering all currently
* defined meta tags.
* `manage_meta_emit_encoding` - boolean which sets whether or not to
emit encoding `meta` tag defaults to `true`.
* `manage_meta_emit_encoding=` - setter for manage_meta_emit_encoding.
(set to false if you want to include your encoding by hand)
* `manage_meta_set_encoding()` - allows setting character encoding
* `manage_meta_set_html_version()` - allows setting html version to
html5, html4, or xhtml

private methods:

* `_manage_meta_init` - initializes required instance variables. `_manage_meta_init` is
called automatically from the public methods
* `_manage_meta_sym_to_name` - returns Content-Length when given :content_length, etc.
It works with either symbols or strings and strips extra underscores and hyphens
* `_manage_meta_name_to_sym` - returns symbol :foo_bar_baz when given a name of the form 'Foo-Bar-Baz'.
It also works when given a symbol and strips extra underscores and hyphens.

The instance variables are three hashes. None have readers or writers:

* `@manage_meta_meta_hash` - a Hash containing mapping defined meta tag names to content values
* `@manage_meta_format_hash` - a Hash mapping known meta tag format symbols to actual format strings.
Contains entries such as `:content_type => :named` and `:content_length => :http_equiv`
* `@manage_meta_name_to_format` - a Hash mapping meta tag name strings to known formats. Formats
are initialized to the three symbols: `:named`, `:http_equiv`, and `:canonical` (see below). `add_meta_format()`
is used to add formats to this hash.

The Details
--------------

Here are the ugly details

### Methods in Detail ###

#### `add_meta()` ####

*add_meta()* accepts values in any of three formats:

* `add_meta(name, value[, :format => :format_name] [, :no_capitalize => true/false])`
* `add_meta(name, value[, :format => :format_name][, :no_capitalize => true/false]) do ... end`
* `add_meta(name[, :format => :format_name][, :no_capitalize => true/false]) do ... end`

Arguments:

* *name* must be something which responds to 'to_s'. It will be used for the *name* (or *http-equiv*)
attribute of the meta tag.
* *value* must be something which responds to 'to_s' and is not a Hash. Normally it will simply
be a string. If given, it supplies the leading part of the *content* attribute of the meta tag
* The *option* :format must supply an existing key in @manage_meta_format_hash. It is
used to associate a meta tag format with *name*. If not given and not currently defined
in `@manage_meta_format_hash`, it will be set to *:named*. (see below for details)
* The *option* :no_capitalize controls capitalization of each word in the *name* attribute
when translated to a String. This was added to deal with Facebook Open Graph *property* tags
which are of the form 'og:title' and 'fb:admins', etc. :no_capitalize should be a boolean.
* The *optional block* is evaluated and the return value is used as the second [or only] part
of the _content_ attribute of the meta tag.

Three meta tag formats are defined automatically:

* `:named => '<meta name="#{name}" content="#{content}" charset="utf-8" />'`
* `:http_equiv => '<meta http-equiv="#{name}" content="#{content}" charset="utf-8" />'`
* `:canonical => '<link rel="canonical" href="#{content}" />'`

The _@manage_meta_name_to_format_ is populated with entries mapping known HTTP-EQUIV tags
and the CANONICAL Google link tag to the correct format.

#### `del_meta()` ####

`del_meta()` is almost useless. It's there in case you want to get ride of a default tag.

`del_meta(name)`

If the meta tag is defined in `@manage_meta_meta_hash`, then it will be deleted.
Nothing bad happens if it isn't.

#### `add_meta_format()` ####

`add_meta_format(format_name, format_string)` adds the `format_string` to
`@manage_meta_format_hash` under the key `format_name`

*format_name* will be converted to a symbol using `_manage_meta_sym_to_name()`.

It's your responsibility to format the string properly:
`render_meta()` will replace `#{name}` and `#{content}` with the string values given for the meta
tag - if present. It is not an error to omit either or both `#{name}` and/or `#{content}`.
The value used for `#{name}` result of calling `_manage_meta_sym_to_name()` on the meta element key.

#### render_meta() ####

`render_meta()`

simply goes through all the defined key, value pairs in @manage_meta_meta_hash and
returns their associated format strings after replacing the `#{name}` and `#{content}`
symbols with their values.

`#{name}` is replaced with the meta tag key [as in `:content_type`] passed through
`_manage_meta_sym_to_name()`.

`#{value}` is replaced by the value assigned in `@manage_meta_meta_hash`.

#### manage_meta_set_encoding( encoding ) ####

sets the instance variable `@manage_meta_encoding` to `encoding`.
The default value is `utf-8`, so don't bother unless you're using
something else.

NOTE: Character encoding strings are

* always emitted for HTML 5 pages
* Only emitted for HTML 4.01 and XHTML pages IF a `content_type` meta
tag is added via `add_meta()`

#### manage_meta_set_html_version( version ) ####

sets the instance variable `@manage_meta_html_version` to the symbol
associated with string `version`. Version is decoded using regular
expressions which match strings like html5, html 5, HTML  5, html 4,
etc.

The actual value is one of the symbols: :html5, :html4, or :xhtml.

An ArgumentError is raised if `version` does not match a known string.

The value of `@manage_meta_html_version` is used in prepending a
`charset` meta tag to string emitted by `render_meta`.

### Instance Variables in Detail ###

All three hashes use symbols for keys. 

#### `@manage_meta_format_hash` ####

maps format keys to format strings. See `add_meta_format()` above for details

keys are symbols,

values are strings which are used to render meta tags

####  `@manage_meta_meta_hash` ####

Maps meta tag `name` keys to values to insert into the `content` field of the meta tag
element.

keys are symbols which are used for the names of meta tags

values are strings

#### `@manage_meta_name_to_format` ####

Maps meta tag name symbols to meta tag format string symbols. Contains entries
such as `:content_length => :http_equiv`

both keys and values are symbols

#### `@manage_meta_emit_encoding` ####

Boolean which is `true` or `false`. Controls whether or not an
encoding meta tag is emitted

#### `@manage_meta_encoding` ####

String which is used in the `charset` meta tag which is emitted

#### `@manage_meta_html_version` ####

Symbol which represents the html version used in the page. Possible
values are `html4`, `html4`, and `xhtml`.  Currently only used to
control what type of `charset` encoding meta tag to emit.

A Facebook Open Graph Sketch
-----------------------

First define an appropriate format:

    `add_meta_format :property, '<meta property="#{name}" content="#{content}" charset="utf-8">'`

Then, add each Open Graph meta tag you need, specifying both :format and :no_capitalize options:

    `add_meta 'og:title', 'This is a Title', :format => :property, :no_capitalize => true`
    
You can specify the Open Graph property name as a string (above) or as a symbol `:'og:title'`,
but - inasmuch as they contain colons (:) - you need to enclose them in quotes.
