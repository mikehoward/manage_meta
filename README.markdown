ManageMeta
============

ManageMeta is yet another meta tag manager for Rails 3.x. Its features are: recognizes tags
should render as HTTP-EQUIV; supports the Google 'canonical' link; is extensible; is non-intrusive

How it works
-----------

Include the gem by adding this to your Gemfile file

`gem "manage_meta", :git => "git://github.com/mikehoward/manage_meta.git"`

Then, in your controller actions, call _add_meta_ for each meta tag you want
to define.

`add_meta :author, 'Fred Fink'`

If there are meta tags you don't want to define, you can use _del_meta_ to remove them.
At present there are only two automatically defined: 'robots' and 'generator'. You may
also redefine them by using _add_meta_ to give them new values.

If there is a meta tag which requires a currently unsupported format, you may add it
using _add_format_.

Finally, edit app/views/layouts/application.html.erb - or equivalent - to insert

`<%= render_meta %>`

into the _head_ section of your HTML output. This will render and return all of the
defined meta tags.

What it Adds
------------

ManageMeta defines four (4) methods and three (3) instance variables into all classes
derived from ApplicationController

The methods are:

* add_meta - adds a meta tag
* del_meta - which deletes a meta tag
* add_format - which adds a meta tag format
* render_meta - which returns a string rendering all currently defined meta tags.

The instance variables are:

* @manage_meta_meta_hash - a Hash containing mapping defined meta tag names to content values
* @manage_meta_format_hash - a Hash mapping known meta tag format strings to actual format strings
* @manage_meta_name_to_format - a Hash mapping meta tag name strings to known formats

The Details
--------------

Here are the ugly details

### Methods in Detail ###

#### add_meta ####

_add_meta_ accepts values in any of three formats:

`add_meta(name, value[, :format => :format_name])`
`add_meta(name, value[, :format => :format_name]) do ... end`
`add_meta(name[, :format => :format_name]) do ... end`

* name must be something which responds to 'to_s'. It will be used for the _name_ (or _http-equiv_)
attribute of the meta tag.
* value must be something which responds to 'to_s' and is not a Hash. Normally it will simply
be a string. If given, it supplies the leading part of the _content_ attribute of the meta tag
* The single option :format must supply an existing key in @manage_meta_format_hash. It is
used to associate a meta tag format with _name_. If not given and not currently defined in
@manage_meta_format_hash, it will be set to _:named_. (see below for details)
* The optional block is evaluated and the return value is used as the second [or only] part
of the _content_ attribute of the meta tag.

Three meta tag formats are defined automatically:

* `:named => '<meta name="#{name}" content="#{content}" char-encoding="utf-8" />'`
* `:http_equiv => '<meta http-equiv="#{name}" content="#{content}" char-encoding="utf-8" />'`
* `:canonical => '<link rel="canonical" href="#{content}" />'`

The _@manage_meta_name_to_format_ is populated with entries mapping known HTTP-EQUIV tags
and the CANONICAL Google link tag to the correct format.

#### del_meta ####

_del_meta_ is almost useless. It's there in case you want to get ride of a default tag.

`del_meta(name)`

where _name_ is something which responds to 'to_s' [or is a string]. If the meta tag is
defined in @manage_meta_meta_hash, then it will be deleted. Nothing bad happens if it isn't.

#### add_format_ ####

`add_format(format_name, format_string)`

_format_name__ will be converted to a symbol.

_format_string_ will be the value of @manage_meta_format_hash[_format_name.to_sym_].

It's your responsibility to format the string properly.

_render_meta_ will replace _name_ and _content_ with the string values given for the meta
tag - if present. It is not an error to omit either or both _name_ and/or _content_

#### render_meta ####

`render_meta`

simply goes through all the defined key, value pairs in @manage_meta_meta_hash and
returns their associated format strings after replacing the _#{name}_ and _#{content}_
symbols with their values.

### Instance Variables in Detail ###

#### manage_meta_format_hash ####

keys are symbols,

values are strings which are used to render meta tags

####  manage_meta_meta_hash ####

keys are strings which are used for the names of meta tags

values are symbols which are keys in @manage_meta_format_hash

#### manage_meta_name_to_format ####

keys are strings which map meta tag names to keys in @manage_meta_format_hash
