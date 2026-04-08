# Apartment::Activejob

ActiveJob support for Apartment

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apartment-activejob'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apartment-activejob

## Usage

Create a new initialization file active_job.rb in your project with the contents

```ruby
class ActiveJob::Base
  include Apartment::ActiveJob
end
```

You will need to restart your rails server for this to take effect.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/apartment-activejob/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
