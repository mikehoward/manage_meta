require 'manage_meta/manage_meta'
require 'manage_meta/railtie' if defined? Rails
puts "in #{__FILE__}: #{__LINE__}; self: #{self}"

# if defined? Rails
#   class ApplicationController <ActionController::Base
#     include ManageMeta
#   end
# end
