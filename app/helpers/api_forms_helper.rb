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

  def map_form_field(form, key, value, form_properties)
    case value.class.to_s
    when 'String'
      form.text_field key, placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1', value: value, class: 'form-control'
    when 'Integer'
      form.number_field key, placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1', value: value, class: 'form-control'
    when 'Array'
      form.select key, options_for_select(form_properties[key]['options'].nil? ? value : form_properties[key]['options'] ), { multiple: true }, {class: "form-control array_select", name: "data[#{key}][]", default_value: value.to_s }
    when 'TrueClass', 'FalseClass'
      form.check_box key, checked: value
    when 'Hash'
      render partial: 'comfy/admin/api_forms/jsoneditor', locals: {form: form, key: key, value: value} 
    else
      form.text_field key, placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1',  value: value, class: 'form-control'
    end
  end

  def map_form_field_type(data_type)
    case data_type
    when 'String'
      'Text field'
    when 'Integer'
      'Number field'
    when 'Array'
      'Multiselect'
    when 'TrueClass', 'FalseClass'
      'Checkbox'
    when 'Hash'
      'Json input'
    else
      'String'
    end
  end
end
  