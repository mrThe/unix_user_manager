# UnixUserManager gem

Management tool for unix users. Manually edits `/etc/passwd`, `/etc/shadow` and `/etc/groups`.

It will not read nor write anything to your files, but use it on your own risk!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unix_user_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install unix_user_manager

## Usage

```ruby
  passwd = `sudo cat /etc/passwd` # File.read('/etc/passwd') # your process should have permission
  group  = `sudo cat /etc/group`  # File.read('/etc/group') # your process should have permission
  shadow = `sudo cat /etc/shadow` # File.read('/etc/shadow') # your process should have permission

  # initialize
  um = UnixUserManager.new passwd: passwd, group: group, shadow: shadow

  # get some uniq id for you new group and user
  new_id = um.available_id(min_id: 100, max_id: 500, preffered_ids: [200, 300, 333, 400, 500], recursive: false) # 42

  # add new user
  um.users.add(name: "risky_man", uid: new_id, gid: new_id, shell: '/bin/bash', home_directory: '/home/riskiy_man') # true

  # add new user with a password
  um.users.add(name: "risky_man", uid: new_id, gid: new_id, shell: '/bin/bash', home_directory: '/home/riskiy_man', password: 'my$ecret', salt: 'mysalt', algorithm: :sha512) # true
  # `shell` and `home_directory` params are optional with default values as shown above

  # password hashing notes:
  # - Hashing is performed using pure-Ruby unix-crypt ($6$, $5$, $1$) via the unix-crypt gem
  # - Supported algorithms: :sha512 ($6$), :sha256 ($5$), :md5 ($1$)
  # - You can also pass encrypted_password to use a precomputed crypt hash as-is
  # - Salt is required to get deterministic hashes in tests; if omitted, a random salt is used

  # add new group
  um.groups.add(name: "risky_group", uname: "risky_man", gid: new_id) # true

  # edit existing user (returns true if valid and queued for build)
  um.users.edit(name: "games", uid: 420, gid: 420, home_directory: "/home/games", shell: "/bin/zsh") # true/false

  # edit user password in shadow (either provide raw or already encrypted)
  um.users.edit_shadow(name: "games", password: "my$ecret", salt: "mysalt", algorithm: :sha512) # true/false
  # or provide an already-encrypted hash (unchanged and used as is)
  um.users.edit_shadow(name: "games", encrypted_password: "$6$mysalt$...hash...") # true/false
  # or clear password (set to placeholder '!!')
  um.users.edit_shadow(name: "games") # true/false

  # examples with different algorithms
  um.users.edit_shadow(name: "games", password: "my$ecret", salt: "mysalt", algorithm: :sha256) # => $5$mysalt$...
  um.users.edit_shadow(name: "games", password: "my$ecret", salt: "mysalt", algorithm: :md5)    # => $1$mysalt$...

  # edit existing group (change gid and member list)
  um.groups.edit(name: "games", gid: 420, uname: "games,user1,user2") # true/false

  # delete existing user (removes from both /etc/passwd and /etc/shadow)
  um.users.delete(name: "risky_man") # true/false

  # delete existing group
  um.groups.delete(name: "risky_group") # true/false

  # build new configs
  um.users.build_passwd # new contents for /etc/passwd
  um.users.build_shadow # new contents for /etc/shadow
  um.groups.build       # new contents for /etc/group

  # or
  um.users.build # { passwd: "...content...", shadow: "...content..." } new contents for /etc/passwd and /etc/shadow

  # or build only new lines
  um.users.build_passwd_new_records # new lines for /etc/passwd, eg "risky_man:x:42:42::/dev/null:/bin/bash"
  um.users.build_shadow_new_records # new lines for /etc/shadow, eg "risky_man:!!:::::::"
  um.groups.build_new_records       # new lines for /etc/group,  eg "risky_group:x:42:risky_man"
```

## TODO

1. Add support for gshadow

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/mrThe/unix_user_manager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
