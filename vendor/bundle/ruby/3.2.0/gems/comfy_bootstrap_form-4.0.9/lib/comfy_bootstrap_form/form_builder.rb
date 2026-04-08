# frozen_string_literal: true

require_relative "bootstrap_options"

module ComfyBootstrapForm
  class FormBuilder < ActionView::Helpers::FormBuilder

    FIELD_HELPERS = %w[
      color_field date_field datetime_field email_field month_field
      password_field phone_field range_field search_field text_area
      text_field rich_text_area time_field url_field week_field
    ].freeze

    DATE_SELECT_HELPERS = %w[
      date_select datetime_select time_select
    ].freeze

    delegate :content_tag, :capture, :concat, to: :@template

    # Bootstrap settings set on the form itself
    attr_accessor :form_bootstrap

    def initialize(object_name, object, template, options)
      @form_bootstrap = ComfyBootstrapForm::BootstrapOptions.new(options.delete(:bootstrap))
      super(object_name, object, template, options)
    end

    # Wrapper for all field helpers. Example usage:
    #
    #   bootstrap_form_with model: @user do |form|
    #     form.text_field :name
    #   end
    #
    # Output of the `text_field` will be wrapped in Bootstrap markup
    #
    FIELD_HELPERS.each do |field_helper|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{field_helper}(method, options = {})
          bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
          return super if bootstrap.disabled
          draw_form_group(bootstrap, method, options) do
            super(method, options)
          end
        end
      RUBY_EVAL
    end

    # Wrapper for datetime select helpers. Boostrap options are sent via options hash:
    #
    #   date_select :birthday, bootstrap: {label: {text: "Custom"}}
    #
    DATE_SELECT_HELPERS.each do |select_helper|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{select_helper}(method, options = {}, html_options = {}, &block)
          bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
          return super if bootstrap.disabled

          add_css_class!(html_options, "d-inline-block w-auto")
          add_css_class!(html_options, "custom-select") if bootstrap.custom_control

          draw_form_group(bootstrap, method, html_options) do
            content_tag(:div, class: "#{select_helper}") do
              super(method, options, html_options, &block)
            end
          end
        end
      RUBY_EVAL
    end

    # Wrapper for the number field. It has default changed from `step: "1"` to `step: "any"`
    # to prevent confusion when dealing with decimal numbers.
    #
    #   number_field :amount, step: 5
    #
    def number_field(method, options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      options.reverse_merge!(step: "any")
      return super(method, options) if bootstrap.disabled

      draw_form_group(bootstrap, method, options) do
        super(method, options)
      end
    end

    # Wrapper for select helper. Boostrap options are sent via options hash:
    #
    #   select :choices, ["a", "b"], bootstrap: {label: {text: "Custom"}}
    #
    def select(method, choices = nil, options = {}, html_options = {}, &block)
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      add_css_class!(html_options, "custom-select") if bootstrap.custom_control

      draw_form_group(bootstrap, method, html_options) do
        super(method, choices, options, html_options, &block)
      end
    end

    # Wrapper for file_field helper. It can accept `custom_control` option.
    #
    #   file_field :photo, bootstrap: {custom_control: true}
    #
    def file_field(method, options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      draw_form_group(bootstrap, method, options) do
        if bootstrap.custom_control
          content_tag(:div, class: "custom-file") do
            add_css_class!(options, "custom-file-input")
            remove_css_class!(options, "form-control")
            label_text = options.delete(:placeholder)
            concat super(method, options)

            label_options = { class: "custom-file-label" }
            label_options[:for] = options[:id] if options[:id].present?
            concat label(method, label_text, label_options)
          end
        else
          super(method, options)
        end
      end
    end

    # Wrapper around radio button. Example usage:
    #
    #   radio_button :choice, "value", bootstrap: {label: {text: "Do you agree?"}}
    #
    def radio_button(method, tag_value, options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      help_text = draw_help(bootstrap)
      errors    = draw_errors(bootstrap, method)

      add_css_class!(options, "form-check-input")
      add_css_class!(options, "is-invalid") if errors.present?

      label_text = nil
      if (custom_text = bootstrap.label[:text]).present?
        label_text = custom_text
      end

      fieldset_css_class = "form-group"
      fieldset_css_class += " row" if bootstrap.horizontal?
      fieldset_css_class += " #{bootstrap.inline_margin_class}" if bootstrap.inline?

      content_tag(:fieldset, class: fieldset_css_class) do
        draw_control_column(bootstrap, offset: true) do
          if bootstrap.custom_control
            content_tag(:div, class: "custom-control custom-radio") do
              add_css_class!(options, "custom-control-input")
              remove_css_class!(options, "form-check-input")
              concat super(method, tag_value, options)
              concat label(method, label_text, value: tag_value, class: "custom-control-label")
              concat errors     if errors.present?
              concat help_text  if help_text.present?
            end
          else
            content_tag(:div, class: "form-check") do
              concat super(method, tag_value, options)
              concat label(method, label_text, value: tag_value, class: "form-check-label")
              concat errors     if errors.present?
              concat help_text  if help_text.present?
            end
          end
        end
      end
    end

    # Wrapper around checkbox. Example usage:
    #
    #   checkbox :agree, bootstrap: {label: {text: "Do you agree?"}}
    #
    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      help_text = draw_help(bootstrap)
      errors    = draw_errors(bootstrap, method)

      add_css_class!(options, "form-check-input")
      add_css_class!(options, "is-invalid") if errors.present?

      label_text = nil
      if (custom_text = bootstrap.label[:text]).present?
        label_text = custom_text
      end

      fieldset_css_class = "form-group"
      fieldset_css_class += " row" if bootstrap.horizontal?
      fieldset_css_class += " #{bootstrap.inline_margin_class}" if bootstrap.inline?

      content_tag(:fieldset, class: fieldset_css_class) do
        draw_control_column(bootstrap, offset: true) do
          if bootstrap.custom_control
            content_tag(:div, class: "custom-control custom-checkbox") do
              add_css_class!(options, "custom-control-input")
              remove_css_class!(options, "form-check-input")
              concat super(method, options, checked_value, unchecked_value)
              concat label(method, label_text, class: "custom-control-label")
              concat errors     if errors.present?
              concat help_text  if help_text.present?
            end
          else
            content_tag(:div, class: "form-check") do
              concat super(method, options, checked_value, unchecked_value)
              concat label(method, label_text, class: "form-check-label")
              concat errors     if errors.present?
              concat help_text  if help_text.present?
            end
          end
        end
      end
    end

    # Helper to generate multiple radio buttons. Example usage:
    #
    #   collection_radio_buttons :choices, ["a", "b"], :to_s, :to_s %>
    #   collection_radio_buttons :choices, [["a", "Label A"], ["b", "Label B"]], :first, :second
    #   collection_radio_buttons :choices, Choice.all, :id, :label
    #
    # Takes bootstrap options:
    #   inline: true            - to render inputs inline
    #   label: {text: "Custom"} - to specify a label
    #   label: {hide: true}     - to not render label at all
    #
    def collection_radio_buttons(method, collection, value_method, text_method, options = {}, html_options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      args = [bootstrap, :radio_button, method, collection, value_method, text_method, options, html_options]
      draw_choices(*args) do |m, v, opts|
        radio_button(m, v, opts.merge(bootstrap: { disabled: true }))
      end
    end

    # Helper to generate multiple checkboxes. Same options as for radio buttons.
    # Example usage:
    #
    #   collection_check_boxes :choices, Choice.all, :id, :label
    #
    def collection_check_boxes(method, collection, value_method, text_method, options = {}, html_options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      content = "".html_safe
      unless options[:include_hidden] == false
        content << hidden_field(method, multiple: true, value: "")
      end

      args = [bootstrap, :check_box, method, collection, value_method, text_method, options, html_options]
      content << draw_choices(*args) do |m, v, opts|
        opts[:multiple]       = true
        opts[:include_hidden] = false
        check_box(m, opts.merge(bootstrap: { disabled: true }), v)
      end
    end

    # Bootstrap wrapper for readonly text field that is shown as plain text.
    #
    #   plaintext(:value)
    #
    def plaintext(method, options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      draw_form_group(bootstrap, method, options) do
        remove_css_class!(options, "form-control")
        add_css_class!(options, "form-control-plaintext")
        options[:readonly] = true
        ActionView::Helpers::FormBuilder.instance_method(:text_field).bind(self).call(method, options)
      end
    end

    # Add bootstrap formatted submit button. If you need to change its type or
    # add another css class, you need to override all css classes like so:
    #
    #   submit(class: "btn btn-info custom-class")
    #
    # You may add additional content that directly follows the button. Here's
    # an example of a cancel link:
    #
    #   submit do
    #     link_to("Cancel", "/", class: "btn btn-link")
    #   end
    #
    def submit(value = nil, options = {}, &block)
      if value.is_a?(Hash)
        options = value
        value   = nil
      end

      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))
      return super if bootstrap.disabled

      add_css_class!(options, "btn")

      form_group_class = "form-group"
      form_group_class += " row" if bootstrap.horizontal?

      content_tag(:div, class: form_group_class) do
        draw_control_column(bootstrap, offset: true) do
          out = super(value, options)
          out << capture(&block) if block_given?
          out
        end
      end
    end

    # Same as submit button, only with btn-primary class added
    def primary(value = nil, options = {}, &block)
      add_css_class!(options, "btn-primary")
      submit(value, options, &block)
    end

    # Helper method to put arbitrary content in markup that renders correctly
    # for the Bootstrap form. Example:
    #
    #   form_group bootstrap: {label: {text: "Label"}} do
    #     "Some content"
    #   end
    #
    def form_group(options = {})
      bootstrap = form_bootstrap.scoped(options.delete(:bootstrap))

      label_options = bootstrap.label.clone
      label_text = label_options.delete(:text)

      label =
        if label_text.present?
          if bootstrap.horizontal?
            add_css_class!(label_options, "col-form-label")
            add_css_class!(label_options, bootstrap.label_col_class)
            add_css_class!(label_options, bootstrap.label_align_class)
          elsif bootstrap.inline?
            add_css_class!(label_options, bootstrap.inline_margin_class)
          end

          content_tag(:label, label_text, label_options)
        end

      form_group_class = "form-group"
      form_group_class += " row"      if bootstrap.horizontal?
      form_group_class += " mr-sm-2"  if bootstrap.inline?

      content_tag(:div, class: form_group_class) do
        content = "".html_safe
        content << label if label.present?
        content << draw_control_column(bootstrap, offset: label.blank?) do
          yield
        end
      end
    end

  private

    # form group wrapper for input fields
    def draw_form_group(bootstrap, method, options)
      label  = draw_label(bootstrap, method, for_attr: options[:id])
      errors = draw_errors(bootstrap, method)

      control = draw_control(bootstrap, errors, method, options) do
        yield
      end

      form_group_class = "form-group"
      form_group_class += " row"      if bootstrap.horizontal?
      form_group_class += " mr-sm-2"  if bootstrap.inline?

      content_tag(:div, class: form_group_class) do
        concat label
        concat control
      end
    end

    def draw_errors(bootstrap, method)
      errors = []

      if bootstrap.error.present?
        errors = [bootstrap.error]
      else
        return if object.nil?

        errors = object.errors[method]

        # If error is on association like `belongs_to :foo`, we need to render it
        # on an input field with `:foo_id` name.
        if errors.blank?
          errors = object.errors[method.to_s.sub(%r{_id$}, "")]
        end
      end

      return if errors.blank?

      content_tag(:div, class: "invalid-feedback") do
        errors.join(", ")
      end
    end

    # Renders label for a given field. Takes following bootstrap options:
    #
    # :text   - replace default label text
    # :class  - css class on the label
    # :hide   - if `true` will render for screen readers only
    #
    # This is how those options can be passed in:
    #
    #   text_field(:value, bootstrap: {label: {text: "Custom", class: "custom"}})
    #
    # You may also just set the label text by passing a string instead of label hash:
    #
    #   text_field(:value, bootstrap: {label: "Custom Label"})
    #
    def draw_label(bootstrap, method, for_attr: nil)
      options = bootstrap.label.dup
      text    = options.delete(:text)

      options[:for] = for_attr if for_attr.present?

      add_css_class!(options, "sr-only") if options.delete(:hide)
      add_css_class!(options, bootstrap.inline_margin_class) if bootstrap.inline?

      if bootstrap.horizontal?
        add_css_class!(options, "col-form-label")
        add_css_class!(options, bootstrap.label_col_class)
        add_css_class!(options, bootstrap.label_align_class)
      end

      label(method, text, options)
    end

    # Renders control for a given field
    def draw_control(bootstrap, errors, _method, options)
      add_css_class!(options, "form-control")
      add_css_class!(options, "is-invalid") if errors.present?

      draw_control_column(bootstrap, offset: bootstrap.label[:hide]) do
        draw_input_group(bootstrap, errors) do
          yield
        end
      end
    end

    # Wrapping in control in column wrapper
    #
    def draw_control_column(bootstrap, offset:)
      return yield unless bootstrap.horizontal?

      css_class = bootstrap.control_col_class.to_s
      css_class += " #{bootstrap.offset_col_class}" if offset
      content_tag(:div, class: css_class) do
        yield
      end
    end

    # Wraps input field in input group container that allows prepending and
    # appending text or html. Example:
    #
    #   text_field(:value, bootstrap: {prepend: "$.$$"}})
    #   text_field(:value, bootstrap: {append: {html: "<button>Go</button>"}}})
    #
    def draw_input_group(bootstrap, errors, &block)
      prepend_html  = draw_input_group_content(bootstrap, :prepend)
      append_html   = draw_input_group_content(bootstrap, :append)

      help_text = draw_help(bootstrap)

      # Not prepending or appending anything. Bail.
      if prepend_html.blank? && append_html.blank?
        content = capture(&block)
        content << errors     if errors.present?
        content << help_text  if help_text.present?
        return content
      end

      content = "".html_safe
      content << content_tag(:div, class: "input-group") do
        concat prepend_html if prepend_html.present?
        concat capture(&block)
        concat append_html  if append_html.present?
        concat errors       if errors.present?
      end
      content << help_text if help_text.present?
      content
    end

    def draw_input_group_content(bootstrap, type)
      value = bootstrap.send(type)
      return unless value.present?

      content_tag(:div, class: "input-group-#{type}") do
        if value.is_a?(Hash) && value[:html].present?
          value[:html]
        else
          content_tag(:span, value, class: "input-group-text")
        end
      end
    end

    # Drawing boostrap form field help text. Example usage:
    #
    #   text_field(:value, bootstrap: {help: "help text"})
    #
    def draw_help(bootstrap)
      text = bootstrap.help
      return if text.blank?

      content_tag(:small, text, class: "form-text text-muted")
    end

    # Rendering of choices for checkboxes and radio buttons
    def draw_choices(bootstrap, type, method, collection, value_method, text_method, _options, html_options)
      draw_form_group_fieldset(bootstrap, method) do
        if bootstrap.custom_control
          label_css_class = "custom-control-label"

          form_check_css_class = "custom-control"
          form_check_css_class +=
            case type
            when :radio_button then " custom-radio"
            when :check_box    then " custom-checkbox"
            end

          form_check_css_class += " custom-control-inline" if bootstrap.check_inline

          add_css_class!(html_options, "custom-control-input")

        else
          label_css_class = "form-check-label"

          form_check_css_class = "form-check"
          form_check_css_class += " form-check-inline" if bootstrap.check_inline

          add_css_class!(html_options, "form-check-input")
        end

        errors    = draw_errors(bootstrap, method)
        help_text = draw_help(bootstrap)

        add_css_class!(html_options, "is-invalid") if errors.present?

        content = "".html_safe
        collection.each_with_index do |item, index|
          item_value  = item.send(value_method)
          item_text   = item.send(text_method)

          content << content_tag(:div, class: form_check_css_class) do
            concat yield method, item_value, html_options
            concat label(method, item_text, value: item_value, class: label_css_class)
            if ((collection.count - 1) == index) && !bootstrap.check_inline
              concat errors     if errors.present?
              concat help_text  if help_text.present?
            end
          end
        end

        if bootstrap.check_inline
          content << errors     if errors.present?
          content << help_text  if help_text.present?
        end

        content
      end
    end

    # Wrapper for collections of radio buttons and checkboxes
    def draw_form_group_fieldset(bootstrap, method)
      options = {}

      unless bootstrap.label[:hide]
        label_text = bootstrap.label[:text]
        label_text ||= ActionView::Helpers::Tags::Label::LabelBuilder
          .new(@template, @object_name.to_s, method, @object, nil).translation

        add_css_class!(options, "col-form-label pt-0")
        add_css_class!(options, bootstrap.label[:class])

        if bootstrap.horizontal?
          add_css_class!(options, bootstrap.label_col_class)
          add_css_class!(options, bootstrap.label_align_class)
        end

        label = content_tag(:legend, options) do
          label_text
        end
      end

      content_tag(:fieldset, class: "form-group") do
        content = "".html_safe
        content << label if label.present?
        content << draw_control_column(bootstrap, offset: bootstrap.label[:hide]) do
          yield
        end

        if bootstrap.horizontal?
          content_tag(:div, content, class: "row")
        else
          content
        end
      end
    end

    def add_css_class!(options, string)
      css_class = [options[:class], string].compact.join(" ")
      options[:class] = css_class if css_class.present?
    end

    def remove_css_class!(options, string)
      css_class = options[:class].to_s.split(" ")
      options[:class] = (css_class - [string]).compact.join(" ")
      options.delete(:class) if options[:class].blank?
    end

  end
end
