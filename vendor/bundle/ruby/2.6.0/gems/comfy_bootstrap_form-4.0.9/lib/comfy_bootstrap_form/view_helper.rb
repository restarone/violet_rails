# frozen_string_literal: true

module ComfyBootstrapForm
  module ViewHelper

    # Wrapper for `form_with`. Passing in Bootstrap form builder.
    def bootstrap_form_with(**options, &block)
      bootstrap_options = options[:bootstrap] || {}

      css_classes = options.delete(:class)

      if bootstrap_options[:layout].to_s == "inline"
        css_classes = [css_classes, "form-inline"].compact.join(" ")
      end

      form_options = options.reverse_merge(builder: ComfyBootstrapForm::FormBuilder)
      form_options.merge!(class: css_classes) unless css_classes.blank?

      supress_form_field_errors do
        form_with(**form_options, &block)
      end
    end

    def bootstrap_form_for(record, options = {}, &block)
      options[:html] ||= {}

      bootstrap_options = options[:bootstrap] || {}

      css_classes = options[:html].delete(:class)

      if bootstrap_options[:layout].to_s == "inline"
        css_classes = [css_classes, "form-inline"].compact.join(" ")
      end

      options.reverse_merge!(builder: ComfyBootstrapForm::FormBuilder)
      options[:html].merge!(class: css_classes) unless css_classes.blank?

      supress_form_field_errors do
        form_for(record, options, &block)
      end
    end

  private

    # By default, Rails will wrap form fields with extra html to indicate
    # inputs with errors. We need to handle this in the builder to render
    # Bootstrap specific markup. So we need to bypass this.
    def supress_form_field_errors
      original_proc = ActionView::Base.field_error_proc
      ActionView::Base.field_error_proc = proc { |input, _instance| input }
      yield
    ensure
      ActionView::Base.field_error_proc = original_proc
    end

  end
end
