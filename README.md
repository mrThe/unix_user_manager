# UnixUserManager gem

Management tool for unix users. Manually edits `/etc/passwd`, `/etc/shadow` and `/etc/groups`.

It will not write anything to your files, but use it on your own risk!

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
  passwd = `cat /etc/passwd`
  group  = `cat /etc/group`
  shadow = `cat /etc/shadow`

  # initialize
  um = UnixUserManager.new passwd: passwd, group: group, shadow: shadow

  # get some uniq id for you new group and user
  new_id = um.available_id(min_id: 100, max_id: 500, preffered_ids: [200, 300, 333, 400, 500], recursive: false) # 42

  # add new user
  um.users.add(name: "risky_man", uid: new_id, gid: new_id) # true

  # add new group
  um.groups.add(name: "risky_group", uname: "risky_man", gid: new_id) # true

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

1. Add support for edit users/groups
2. Add support for destroy users/groups
3. Add support for user with passwords
5. Add support for gshadow

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/unix_user_manager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
