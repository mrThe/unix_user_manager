$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
Dir["./spec/support/**/*.rb"].each { |f| require f }

require 'unix_user_manager'

def etc_passwd_content
  File.read('spec/fixtures/etc_passwd')
end

def etc_shadow_content
  File.read('spec/fixtures/etc_shadow')
end

def etc_group_content
  File.read('spec/fixtures/etc_group')
end
