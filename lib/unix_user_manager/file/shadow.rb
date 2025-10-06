require 'securerandom'

class UnixUserManager::File::Shadow < UnixUserManager::File::LineFileBase
  def initialize(source)
    @edited_records = {}
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

  def build
    super
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:#{data[:password] || '!!'}:::::::" }.join("\n")
  end

  private

  def parse_key_and_id(fields)
    [fields[0], true]
  end

  def apply_edits(parts, edits)
    parts[1] = edits[:password] unless edits[:password].nil?
    parts
  end
end
