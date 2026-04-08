# ComfyBootstrapForm

**bootstrap_form** is a Rails form builder that makes it super easy to integrate
[Bootstrap 4](https://getbootstrap.com/) forms into your Rails application.

[![Gem Version](https://img.shields.io/gem/v/comfy_bootstrap_form.svg?style=flat)](http://rubygems.org/gems/comfy_bootstrap_form)
[![Gem Downloads](https://img.shields.io/gem/dt/comfy_bootstrap_form.svg?style=flat)](http://rubygems.org/gems/comfy_bootstrap_form)
[![Build Status](https://img.shields.io/travis/comfy/comfy-bootstrap-form.svg?style=flat)](https://travis-ci.org/comfy/comfy-bootstrap-form)
[![Coverage Status](https://img.shields.io/coveralls/comfy/comfy-bootstrap-form.svg?style=flat)](https://coveralls.io/r/comfy/comfy-bootstrap-form?branch=master)
[![Gitter](https://badges.gitter.im/comfy/comfortable-mexican-sofa.svg)](https://gitter.im/comfy/comfortable-mexican-sofa)

## Requirements

- Rails 5.0+
- Bootstrap 4.0.0+

## Installation

Add gem to your Gemfile and run `bundle install`

```ruby
gem "comfy_bootstrap_form", "~> 4.0.0"
```

## Usage

Here's a simple example:

```erb
<%= bootstrap_form_with model: @user do |form| %>
  <%= form.email_field :email %>
  <%= form.password_field :password %>
  <%= form.check_box :remember_me %>
  <%= form.submit "Log In" %>
<% end %>
```

This will generate HTML similar to this:

```html
<form action="/users" accept-charset="UTF-8" data-remote="true" method="post">
  <input name="utf8" type="hidden" value="&#x2713;" />
  <input type="hidden" name="authenticity_token" value="AUTH_TOKEN" />
  <div class="form-group">
    <label for="user_email">Email</label>
    <input class="form-control" type="email" name="user[email]" id="user_email" />
  </div>
  <div class="form-group">
    <label for="user_password">Password</label>
    <input class="form-control" type="password" name="user[password]" id="user_password" />
  </div>
  <fieldset class="form-group">
    <div class="form-check">
      <input name="user[remember_me]" type="hidden" value="0" />
      <input class="form-check-input" type="checkbox" value="1" name="user[remember_me]" id="user_remember_me" />
      <label class="form-check-label" for="user_remember_me">Remember me</label>
    </div>
  </fieldset>
  <div class="form-group">
    <input type="submit" name="commit" value="Log In" class="btn" data-disable-with="Log In" />
  </div>
</form>
```

## Form helpers

#### bootstrap_form_with

Wrapper around `form_with` helper that's available in Rails 5.1 and above.
Here's an example:

```erb
<%= bootstrap_form_with model: @person, scope: :user do |form| %>
  <%= form.email_field :email %>
  <%= form.submit %>
<% end %>
```

#### bootstrap_form_for

Wrapper around `form_for` helper that's available in all Rails 5 versions.
Here's an example:

```erb
<%= bootstrap_form_for @person, as: :user do |form| %>
  <%= form.email_field :email %>
  <%= form.submit %>
<% end %>
```

## Supported form field helpers

This gem wraps most of the default form field helpers. Here's the current list:

```
color_field     file_field      phone_field   text_field
date_field      month_field     range_field   time_field
datetime_field  number_field    search_field  url_field
email_field     password_field  text_area     week_field
date_select     time_select     datetime_select
check_box       radio_button    rich_text_area
collection_check_boxes
collection_radio_buttons
```

#### Radio Buttons and Checkboxes

To render collection of radio buttons or checkboxes we use the same helper that
comes with Rails. The only difference is that it doesn't accept a block. This
gem takes care of rendering of labels and inputs for you.

```erb
<%= form.collection_radio_buttons :choices, ["red", "green", "blue"], :to_s, :to_s %>
<%= form.collection_check_boxes   :choices, Choices.all, :id, :label %>
```

You may choose to render inputs inline:

```erb
<%= form.collection_check_boxes :choices, Choices.all, :id, :label, bootstrap: { check_inline: true } %>
```

#### Submit

Submit button is automatically wrapped with Bootstrap markup. Here's how it looks:

```erb
<%= form.submit %>
<%= form.submit "Submit" %>
<%= form.primary %>
```

You can also pass in a block of content that will be appended next to the button:

```erb
<%= form.submit "Save" do %>
  <a href="/" class="btn btn-link">Cancel</a>
<% end %>
```

#### Plaintext helper

There's an additional field helper that render read-only plain text values:

```erb
<%= form.plaintext :value %>
```

#### Form Group

When you need to wrap arbitrary content in markup that renders correctly in
Bootstrap form:

```erb
<%= form.form_group do %>
  Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua.
<% end %>
```

If you need to add a label:

```erb
<%= form.form_group bootstrap: { label: {text: "Lorem" }} do %>
  Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua.
<% end %>
```

## Bootstrap options

Here's a list of all possible bootstrap options you can pass via `:bootstrap`
option that can be attached to the `bootstrap_form_with` and any field helpers
inside of it:

```
layout:               "vertical"
label_col_class:      "col-sm-2"
control_col_class:    "col-sm-10"
label_align_class:    "text-sm-right"
inline_margin_class:  "mr-sm-2"
label:                {}
append:               nil
prepend:              nil
help:                 nil
error:                nil
check_inline:         false
custom_control:       true
```

Options applied on the form level will apply to all field helpers. Options
on field helpers will override form-level options. For example, here's a form
where all labels are hidden:

```erb
<%= bootstrap_form_with model: @user, bootstrap: { label: { hide: true }} do |form| %>
  <%= form.email_field :email %>
  <%= form.text_field :username %>
<% end %>
```

Here's an example of a form where one field uses different label alignment:

```erb
<%= bootstrap_form_with model: @user do |form| %>
  <%= form.email_field :email, bootstrap: { label_align_class: "text-sm-left" } %>
  <%= form.text_field :username %>
<% end %>
```

#### Horizontal Form

By default form is rendered as a stack. Labels are above inputs, and inputs
take up 100% of the width. You can change form layout to `horizontal` to put
labels and corresponding inputs side by side:

```erb
<%= bootstrap_form_with model: @user, bootstrap: { layout: "horizontal" } do |form| %>
  <%= form.email_field :email %>
<% end %>
```

#### Inline Form

You may choose to render form elements in one line. Please note that this layout
won't render all form elements. Things like errors messages won't show up right.

```erb
<%= bootstrap_form_with url: "/search", bootstrap: { layout: "inline" } do |form| %>
  <%= form.text_field :query %>
  <%= form.submit "Search" %>
<% end %>
```

#### Label

You can change label generated by Rails to something else:

```erb
<%= form.text_field :value, bootstrap: { label: "Custom Label" } %>
<%= form.text_field :value, bootstrap: { label: {text: "Custom Label" }} %>
```

You may hide label completely (it's still there for screen readers):

```erb
<%= form.text_field :value, bootstrap: { label: { hide: true }} %>
```

Custom CSS class on the label tag? Sure:

```erb
<%= form.text_field :value, bootstrap: { label: { class: "custom-label" }} %>
```

#### Help Text

You may attach help text for pretty much any field type:

```erb
<%= form.text_field :value, bootstrap: { help: "Short helpful message" } %>
```

#### Append and Prepend

Bootstrap allows prepending and appending content to fields via `input-group`.
Here's how this looks:

```erb
<%= form.text_field :value, bootstrap: { prepend: "$", append: "%" } %>
```

If you want to use something like a button, or other html content do this:

```erb
<% button_html = capture do %>
  <button class="btn btn-danger">Don't Press</button>
<% end %>
<%= form.text_field :value, bootstrap: { append: { html: button_html }} %>
```

#### Custom Forms

Bootstrap can replace native browser form elements with custom ones for checkboxes,
radio buttons and file input field. Enabled by default. Example usage:

```erb
<%= form.file_field :photo, bootstrap: { custom_control: true } %>
<%= form.collection_radio_buttons :choice, %w[yes no], :to_s, :to_s, bootstrap: { custom_control: true } %>
```

#### Disabling Bootstrap

You may completely disable bootstrap and use default form builder by passing
`disabled: true` option. For example:

```erb
<%= form.text_field :username, bootstrap: { disabled: true } %>
```

### Gotchas

- In Rails 5.1 `form_with` does not generate ids for inputs. If you want them
  you'll need to override this method: [actionview/lib/action_view/helpers/form_helper.rb#L745](https://github.com/rails/rails/blob/bdc581616b760d1e2be3795c6f0f3ab4b1e125a5/actionview/lib/action_view/helpers/form_helper.rb#L745)
- For inline radio buttons and check boxes you need to add custom css for error
  messages show up. See: [twbs/bootstrap/issues/25540](https://github.com/twbs/bootstrap/issues/25540)
  For now adding `.invalid-feeback { display: block }` will work.

## Demo App

Feel free to take a look at the [Demo App](/demo) to see how everything renders.
Specifically see [form.html.erb](/demo/app/views/bootstrap/form.html.erb) template
for all kinds of different form configurations you can have.

![Demo Preview](/demo/preview.png)

---

Copyright 2018-20 Oleg Khabarov, Released under the [MIT License](LICENSE.md)
