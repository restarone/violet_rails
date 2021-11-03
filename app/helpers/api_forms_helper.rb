module ApiFormsHelper
  def render_form(id)
    # usage in cms  {{ cms:helper render_form, 1 }} here 1 is the id
    # usage in rails = render_form @api_form.id
    @api_form = ApiForm.find_by(id: id)
    if @api_form
      @api_namespace = @api_form.api_namespace
      render partial: 'comfy/admin/api_forms/render'
    end
  end

  def map_form_field(form, key, value, placeholder, required = false)
    case value.class.to_s
    when 'String'
      form.text_field key, placeholder: placeholder, required: required, value: value, class: 'form-control'
    when 'Integer'
      form.number_field key, placeholder: placeholder, required: required, value: value, class: 'form-control'
    when 'Array'
      form.select key, options_for_select(value), { multiple: true }, {class: "form-control array_select", name: "data[#{key}][]", default_value: value.to_s }
    when 'TrueClass', 'FalseClass'
      form.check_box key, checked: value
    when 'Hash'
      render partial: 'comfy/admin/api_forms/jsoneditor', locals: {form: form, key: key, value: value} 
    else
      form.text_field key, placeholder: placeholder, value: value, class: 'form-control'
    end
  end
end
  