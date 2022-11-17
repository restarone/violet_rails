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
      if form_properties[key]['input_type'] == 'radio'
        render partial: 'comfy/admin/api_forms/radio', locals: {form: form, key: key, value: value, form_properties: form_properties}
      else
        if form_properties[key]['select_type'] == 'multi' || !value.present?
          form.select key, options_for_select(value), { multiple: true, include_blank: true}, {class: "form-control array_select", name: "data[properties][#{key}][]", required: form_properties.dig(key, 'required') == '1', default_value: form_properties.dig(key, 'prepopulated_options').present? ? form_properties.dig(key, 'prepopulated_options').to_s : "[]" , placeholder: form_properties.dig(key, 'placeholder'), 'data-tags': !value.present? }
        else
          form.select key, options_for_select(value, form_properties[key]['prepopulated_options_single']), { include_blank: form_properties[key]['placeholder'] }, {class: "form-control", name: "data[properties][#{key}", required: form_properties[key]['required'] == '1' }
        end
      end
    when 'TrueClass', 'FalseClass'
      options = {required: form_properties[key]['required'] == '1', type: 'checkbox'}
      options[:checked] = value if form_properties[key]['prepopulate'] == '1'
      options[:value] = form_properties[key]['prepopulate'] == '1' ? value : 'false'
      form.check_box key, options,  'true', 'false'
    when 'Hash'
      render partial: 'comfy/admin/api_forms/jsoneditor', locals: {form: form, key: key, value: value} 
    else
      options = { placeholder: value, required: form_properties[key]['required'] == '1', class: 'form-control'}
      options[:type] = form_properties[key]['type_validation'] if form_properties[key]['type_validation'].present?
      options[:pattern] = form_properties[key]['pattern'] if form_properties[key]['type_validation'] == ApiForm::INPUT_TYPE_MAPPING[:regex_pattern] && form_properties[key]['pattern'].present?
      options[:value] = value if form_properties[key]['prepopulate'] == '1'
      if form_properties[key]['field_type'] == 'textarea'
        form.text_area key, options
      else
        form.text_field key, options
      end
    end
  end

  def map_non_primitive_data_type(form, type, form_properties = {}, is_edit = false)
    key = form.object.label.to_sym
    case type
    when 'file'
      options = { required:  form_properties.dig(key, 'required') == '1', class: 'form-control', type: 'file', direct_upload: true, onchange: "previewFile(event, '#{key.to_s.parameterize.underscore}_preview')" }
      form.file_field :attachment, options
    when 'richtext'
      options = { placeholder: form_properties.dig(key, 'placeholder'), required: form_properties.dig(key, 'required') == '1' }
      options[:value] = form_properties.dig(key, 'prepopulate') == '1' || is_edit ? form.object.content : ''
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
end
  