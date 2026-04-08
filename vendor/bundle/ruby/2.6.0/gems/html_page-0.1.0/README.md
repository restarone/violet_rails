# HtmlPage

Inject content into an existing HTML document.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "html_page"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install html_page
```

## Usage

This gem simplifies injecting content into an existing HTML document.

Given an HTML document as a string, `HtmlPage::Renderer` can inject strings of
content into the `<head>` and `<body>`:

```rb
renderer = HtmlPage::Renderer.new(
  content: "<html><head></head><body></body></html>",
  head: "<title>Appended to the head!</title>",
  body: "<h1>Appended to the body!</h1>",
)

renderer.render #=> "<html><head><title>Appended to the head!</title></head><body><h1>Appended to the body</h1></body></html>"
```

The gem also includes the `HtmlPage::Capture` class.

Given a Rails helpers as a `context` along with a block, the `Capture` class
simplifies appending content captured from a Rails view into the HTML's `<head>`
and `<body>` tags.

For example, given the `render_html_with_modifications` defined as:

```rb
require "html_page/capture"

module MyRailsHelper
  def render_html_with_modifications(html_page_as_string, &block)
    capturer = HtmlPage::Capture.new(self, &block)

    head, body = capturer.capture

    renderer = HtmlPage::Renderer.new(
      content: html_page_as_string,
      head: head,
      body: body,
    )

    render inline: renderer.render
  end
end
```

The rendered HTML page will include content captured with from the view:

```erb
<%= render_html_with_modifications @html_page_as_string do %>
  <title>
    Without a block argument,
    the contents of the block will be appended to the `head` element
  </title>
<% end %>

<%= render_html_with_modifications @html_page_as_string do |head| %>
  <% head.append do %>
    <title>A single argument, yields the `head1</title>
  <% end %>
<% end %>

<%= render_html_with_modifications @html_page_as_string do |head, body| %>
  <% head.append do %>
    <title>Both the `head1 and `body` can be yielded</title>
  <% end %>
<% end %>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/html_page. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

