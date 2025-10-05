require 'securerandom'

class UnixUserManager::File::Shadow < UnixUserManager::File::Base
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
      salt ||= SecureRandom.hex(8)
      prefix = case algorithm
               when :sha512 then '$6$'
               when :sha256 then '$5$'
               when :md5    then '$1$'
               else '$6$'
               end
      full_salt = "#{prefix}#{salt}$"
      hashed = password.crypt(full_salt)
      hashed = "#{full_salt}#{hashed}" unless hashed.start_with?(full_salt)
      @new_records[name] = { password: hashed }
    else
      @new_records[name] = { password: '!!' }
    end

    true
  end

  def edit(name:, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless exist?(name)

    new_hash = nil
    if encrypted_password && !encrypted_password.to_s.empty?
      new_hash = encrypted_password
    elsif password && !password.to_s.empty?
      salt ||= SecureRandom.hex(8)
      prefix = case algorithm
               when :sha512 then '$6$'
               when :sha256 then '$5$'
               when :md5    then '$1$'
               else '$6$'
               end
      full_salt = "#{prefix}#{salt}$"
      new_hash = password.crypt(full_salt)
      new_hash = "#{full_salt}#{new_hash}" unless new_hash.start_with?(full_salt)
    else
      new_hash = '!!'
    end

    @edited_records[name] = { password: new_hash }
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
        if @edited_records.key?(uname)
          edits = @edited_records[uname]
          parts[1] = edits[:password] unless edits[:password].nil?
          parts.join(':')
        else
          line
        end
      end
    end.join("\n")

    if @new_records.any?
      updated_source + "\n" + build_new_records
    else
      updated_source
    end
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:#{data[:password] || '!!'}:::::::" }.join("\n")
  end
end
