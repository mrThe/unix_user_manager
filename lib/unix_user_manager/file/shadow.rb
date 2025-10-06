require 'securerandom'

class UnixUserManager::File::Shadow < UnixUserManager::File::Base
  def initialize(source)
    @edited_records = {}
    @deleted_records = {}
    super
  end
  def ids(*arg);        raise NotImplementedError; end
  def find(*arg);       raise NotImplementedError; end
  def find_by_id(*arg); raise NotImplementedError; end
  def id_exist?(*arg);  false end

  def add(name:, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless can_add?(name)

    if encrypted_password && !encrypted_password.to_s.empty?
      @new_records[name] = { password: encrypted_password }
    elsif password && !password.to_s.empty?
      hashed = UnixUserManager::Utils::Password.hash(password: password, algorithm: algorithm, salt: salt)
      @new_records[name] = { password: hashed }
    else
      @new_records[name] = { password: '!!' }
    end

    true
  end

  def edit(name:, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless exist?(name)

    new_hash =
      if encrypted_password && !encrypted_password.to_s.empty?
        encrypted_password
      elsif password && !password.to_s.empty?
        UnixUserManager::Utils::Password.hash(password: password, algorithm: algorithm, salt: salt)
      else
        '!!'
      end

    @edited_records[name] = { password: new_hash }
    true
  end

  def delete(name:)
    # If it's a newly added record, remove it from the staged new records
    if @new_records.key?(name)
      @new_records.delete(name)
      return true
    end

    # If it exists in the original data, mark for deletion
    return false unless exist?(name)

    @deleted_records[name] = true
    true
  end

  def build
    updated_source = source.split("\n").map do |line|
      stripped = line.strip
      if stripped[0] == '#'
        line
      else
        parts = line.split(':')
        uname = parts[0]
        # drop deleted entries
        next nil if @deleted_records.key?(uname)
        if @edited_records.key?(uname)
          edits = @edited_records[uname]
          parts[1] = edits[:password] unless edits[:password].nil?
          parts.join(':')
        else
          line
        end
      end
    end.compact.join("\n")

    @new_records.any? ? (updated_source + "\n" + build_new_records) : updated_source
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:#{data[:password] || '!!'}:::::::" }.join("\n")
  end
end
