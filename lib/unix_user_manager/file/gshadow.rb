class UnixUserManager::File::GShadow < UnixUserManager::File::Base
  def initialize(source)
    @edited_records = {}
    @deleted_records = {}
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
    # Fast-path: no edits and no deletions => preserve original source exactly
    if @edited_records.empty? && @deleted_records.empty?
      return @new_records.any? ? (source + "\n" + build_new_records) : source
    end

    updated_source = source.split("\n").map do |line|
      stripped = line.strip
      if stripped[0] == '#'
        line
      else
        parts = line.split(':')
        gname = parts[0]
        next nil if @deleted_records.key?(gname)
        if @edited_records.key?(gname)
          edits = @edited_records[gname]
          new_password = edits[:password].nil? ? parts[1] : edits[:password]
          new_admins = edits[:admins].nil? ? (parts[2] || "") : edits[:admins]
          new_members = edits[:members].nil? ? (parts[3] || "") : edits[:members]
          [gname, new_password, new_admins, new_members].join(':')
        else
          line
        end
      end
    end.compact.join("\n")

    @new_records.any? ? (updated_source + "\n" + build_new_records) : updated_source
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:#{data[:password] || '!'}:#{data[:admins]}:#{data[:members]}" }.join("\n")
  end
end
