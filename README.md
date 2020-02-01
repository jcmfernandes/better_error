# BetterError

[![Build Status](https://travis-ci.org/jcmfernandes/better_error.svg?branch=master)][travis]
[![Gem Version](https://badge.fury.io/rb/better_error.svg)](https://badge.fury.io/rb/better_error)

[travis]: http://travis-ci.org/jcmfernandes/better_error

`BetterError` is an abstract class that inherits from `StandardError` giving it some nice additional abilities.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'better_error'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install better_error

## Usage

`BetterError` is an abstract class. Trying to use it directly will result in an error:

```ruby
raise BetterError
# RuntimeError: abstract class
```

Hence, you must inherit from it:

```ruby
class MyError < BetterError; end
raise MyError, 'it works!'
# MyError: it works!
```

### IDs

It's fairly common to want unique IDs associated to errors. We got you covered:

```ruby
class MyError < BetterError; end
MyError.new.id
# => "05a1671c-0dd3-4fee-a53b-d511a4f2bb61"
```

By default `#id` returns an UUID V4. You can provide your custom ID generator:

```ruby
class MyError < BetterError
  self.id_generator = -> { Time.now.to_i.to_s }
end
MyError.new.id
# => "1580490783"
```

But you can also override the ID generator when creating an instance:

```ruby
class MyError < BetterError; end
MyError.new(id: '42').id
# => "42"
```

### Context and Details

Have you ever found yourself wanting to add metadata to an exception, wishing it featured something like an hash, but ending up cramming it in its message? `BetterError` features `#context` and `#details`. These 2 methods work together, along with `#<<`, in order to make your life easier. Example:

```ruby
class MyError < BetterError; end
error = MyError.new('a message, but could be an array of messages', some_metadata: 42)
error.details
# => ["a message, but could be an array of messages"]
error.context
# => {:some_metadata=>42}
error << 'another message. that could be an array too'
error.details
# => ["a message, but could be an array of messages", "another message, that could be an array too"]
error << {more_metadata: 'ruby!'}
error.context
# => {:some_metadata=>42, :more_metadata=>"ruby!"}
```

Details can actually *drink* from context by using [Liquid](https://shopify.github.io/liquid/). Example:

```ruby
class MyError < BetterError; end
error = MyError.new('everyone loves {{cake}}', cake: 'cheesecake')
error.details
# => ["everyone loves cheesecake"]
```

Liquid is a powerful templating language, so check its website for more complex examples.

### Represent as an Hash

Example:

```ruby
class NotFoundError < BetterError; end
error = NotFoundError.new(['message 1', 'message 2'], metadata: 42")
error.to_h
# {
#   :id=>"05a1671c-0dd3-4fee-a53b-d511a4f2bb61"",
#   :name=>"NotFoundError"",
#   :pretty_name=>"Not Found"",
#   :details=>["message 1", "message 2"],
#   :context=>{:metadata=>42}
# }
```

`#to_h` takes options `include_children:` and `include_backtrace:`. The latter is self-explanatory. The former makes the result to include the tree of exceptions that caused it, as returned by `#cause`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jcmfernandes/better_error. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

Maintained by [João Fernandes](https://www.github.com/jcmfernandes).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BetterError project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jcmfernandes/better_error/blob/master/CODE_OF_CONDUCT.md).
