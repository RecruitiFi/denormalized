# Denormalized

Denormalized facilitates a simplistic guarding of denormalized followers on any write to the specified source of truth.  Denormalized relies on monkey-patching the write methods in ActiveRecord.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'denormalized'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install denormalized

## Usage

Currently only tested to work for ActiveRecord 4.2.x -- it should be fairly easy to adapt it to work with version 5 or 6, but at the time the author hasn't required such use.

For the "denormalized follower", you will need a column that has the same name as the column on the "source of truth".  Here's an example:

```ruby
follower = DenormalizedFollower.find(1)
follower.name
=> "bingo"

source_of_truth = SourceOfTruth.find(1)
source_of_truth.name
=> "bingo"
```

Enabled Denormalized on the "source of truth" and tell it which columns it is responsible for, and which tables should be updated:

```ruby
class SourceOfTruth
  denormalized :name, tables: [:denormalized_followers]
end
```

Then, anytime you utilize a write method that updates the specified columns on the "source_of_truth", any followers will be automatically updated as well, using the same method.

Example:

```ruby
follower = DenormalizedFollower.find(1)
follower.name
=> "bingo"

source_of_truth = SourceOfTruth.find(1)
source_of_truth.name
=> "bingo"

source_of_truth.update_column(:name, "banjo")
follower.name
=> "banjo"
```

As you can see, even a write method that typically skips callbacks will still keep the specified tables up to date.  That is because Denormalized monkey-patches the ActiveRecord writeable methods, so behind the scenes in the above example, `update_column` was also called on the follower.  When Denormalized calls the same methods on followers, it will only pass along specified attributes, any additional attributes will be ignored, so you can safely update attributes that exist on both columns you don't want to sync as long as it's not specified in the source of truth.

## Development

After checking out the repo, run `bin/setup` to install dependencies.  You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.  To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RecruitiFi/denormalized.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
