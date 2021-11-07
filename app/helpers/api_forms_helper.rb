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
      options = { placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1', value: value, class: 'form-control'}
      options[:type] = form_properties[key]['type_validation'] if form_properties[key]['type_validation'].present?
      options[:pattern] = form_properties[key]['pattern'] if form_properties[key]['pattern'].present?
      if form_properties[key]['field_type'] == 'textarea'
        form.text_area key, options
      else
        form.text_field key, options
      end
    when 'Integer'
      form.number_field key, placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1', value: value, class: 'form-control'
    when 'Array'
      if form_properties[key]['select_type'] == 'multi'
        form.select key, options_for_select(form_properties[key]['options'].nil? ? value : form_properties[key]['options'] ), { multiple: true }, {class: "form-control array_select", name: "data[#{key}][]", default_value: value.to_s }
      else
        form.select key, options_for_select(form_properties[key]['options'].nil? ? value : form_properties[key]['options'] ), { include_blank: form_properties[key]['required'] != "1" }, {class: "form-control", name: "data[#{key}][]"  }
      end
    when 'TrueClass', 'FalseClass'
      form.check_box key, checked: value
    when 'Hash'
      render partial: 'comfy/admin/api_forms/jsoneditor', locals: {form: form, key: key, value: value} 
    else
      form.text_field key, placeholder: form_properties[key]['placeholder'], required: form_properties[key]['required'] == '1',  value: value, class: 'form-control'
    end
  end

  def map_non_primitive_data_type(form, type)
    case type
    when 'file'
      form.file_field :attachment, class: 'form-control'
    when 'richtext'
      form.rich_text_area :content
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
  