class UnixUserManager::File::GShadow < UnixUserManager::File::LineFileBase
  def initialize(source)
    super
  end

  def ids(*arg);        raise NotImplementedError; end
  def find(*arg);       raise NotImplementedError; end
  def find_by_id(*arg); raise NotImplementedError; end
  def id_exist?(*arg);  false end

  def add(name:, password: nil, encrypted_password: nil, admins: nil, members: nil)
    return false unless can_add?(name)

    pass_field =
      if encrypted_password && !encrypted_password.to_s.empty?
        encrypted_password
      elsif password && !password.to_s.empty?
        password
      else
        '!'
      end

    @new_records[name] = {
      password: pass_field,
      admins: (admins || "").to_s,
      members: (members || "").to_s
    }

    true
  end

  def edit(name:, password: nil, encrypted_password: nil, admins: nil, members: nil)
    return false unless exist?(name)

    new_password =
      if encrypted_password && !encrypted_password.to_s.empty?
        encrypted_password
      elsif password && !password.to_s.empty?
        password
      else
        nil # leave unchanged when not provided
      end

    @edited_records[name] ||= { password: nil, admins: nil, members: nil }
    @edited_records[name][:password] = new_password unless new_password.nil?
    @edited_records[name][:admins] = admins unless admins.nil?
    @edited_records[name][:members] = members unless members.nil?

    true
  end

  def delete(name:)
    if @new_records.key?(name)
      @new_records.delete(name)
      return true
    end

    return false unless exist?(name)

    @deleted_records[name] = true
    true
  end

  def build
    super
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:#{data[:password] || '!'}:#{data[:admins]}:#{data[:members]}" }.join("\n")
  end

  private

  def parse_key_and_id(fields)
    [fields[0], true]
  end

  def apply_edits(parts, edits)
    gname = parts[0]
    new_password = edits[:password].nil? ? parts[1] : edits[:password]
    new_admins = edits[:admins].nil? ? (parts[2] || "") : edits[:admins]
    new_members = edits[:members].nil? ? (parts[3] || "") : edits[:members]
    [gname, new_password, new_admins, new_members]
  end
end
