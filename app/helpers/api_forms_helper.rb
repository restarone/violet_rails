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
    when 'Array'
      if form_properties[key]['select_type'] == 'multi'
        form.select key, options_for_select(value), { multiple: true}, {class: "form-control array_select", name: "data[properties][#{key}][]", default_value: form_properties[key]['prepopulated_options'].to_s , placeholder: form_properties[key]['placeholder'] }
      else
        form.select key, options_for_select(value), { include_blank: form_properties[key]['placeholder'] }, {class: "form-control", name: "data[properties][#{key}" }
      end
    when 'TrueClass', 'FalseClass'
      options = {required: form_properties[key]['required'] == '1', type: 'checkbox'}
      options[:checked] = value if form_properties[key]['prepopulate'] == '1'
      form.text_field key, options
    when 'Hash'
      render partial: 'comfy/admin/api_forms/jsoneditor', locals: {form: form, key: key, value: value} 
    else
      options = { placeholder: value, required: form_properties[key]['required'] == '1', class: 'form-control'}
      options[:type] = map_input_type(form_properties[key]['type_validation']) if form_properties[key]['type_validation'].present?
      options[:pattern] = form_properties[key]['pattern'] if form_properties[key]['type_validation'] == 'REGEX pattern' && form_properties[key]['pattern'].present?
      options[:value] = value if form_properties[key]['prepopulate'] == '1'
      if value.class.to_s == 'Integer'
        options[:type] = 'number'
      end
      if [ 'TrueClass', 'FalseClass'].include? value.class.to_s
        options[:type] = 'checkbox'
      end
      if form_properties[key]['field_type'] == 'textarea'
        form.text_area key, options
      else
        form.text_field key, options
      end
    end
  end

  def map_non_primitive_data_type(form, type, form_properties = {})
    key = form.object.label.to_sym
    case type
    when 'file'
      options = { required: form_properties[key]['required'] == '1', class: 'form-control', type: 'file' }
      form.text_field :attachment, options
    when 'richtext'
      options = { placeholder: form.object.content, required: form_properties[key]['required'] == '1' }
      options[:value] = form_properties[key]['prepopulate'] == '1' ? form.object.content : ''
      form.rich_text_area :content, options
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

  def map_input_type(type)
    case type
    when 'free text'
      'text'
    when 'number'
      'tel'
    when 'email', 'url', 'date', 'datetime-local'
      type
    else
      'text'
    end
  end
end
  