require 'manage_meta/manage_meta'
if defined? Rails
  class ApplicationController <ActionController::Base
    include ManageMeta
  end
end
