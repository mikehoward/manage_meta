module ManageMeta
  class Railtie < Rails::Railtie
    initializer "application_controller.initialize_manage_meta" do
      ActiveSupport.on_load(:action_controller) do
        include ManageMeta
      end
    end
  end
end
