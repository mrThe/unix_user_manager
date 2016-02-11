class UnixUserManager::Base
  attr_reader :file
  DELEGATED_METHODS = [:ids, :find, :find_by_id, :exist?, :add, :all, :build, :build_new_records].freeze

  def initialize(*args)
    raise NotImplementedError
  end

  def method_missing(method_name, *args, &block)
    if DELEGATED_METHODS.include?(method_name)
      file.send method_name, *args, &block
    else
      super
    end
  end
end
