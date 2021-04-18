// Custom JS for the admin area

if ($('#email_alises_new').length) {
  console.log('loading')
  $('select').select2({
    multiple: false,
    required: true,
  })
}
