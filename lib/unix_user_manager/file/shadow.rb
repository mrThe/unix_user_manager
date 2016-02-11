class UnixUserManager::File::Shadow < UnixUserManager::File::Base
  def ids(*arg);        raise NotImplementedError; end
  def find(*arg);       raise NotImplementedError; end
  def find_by_id(*arg); raise NotImplementedError; end
  def id_exist?(*arg);  false end

  def add(name:)
    return false unless can_add?(name)
    @new_records[name] = { id: nil }

    true
  end

  def build_new_records
    @new_records.map { |name, _| "#{name}:!!:::::::" }.join("\n")
  end
end
