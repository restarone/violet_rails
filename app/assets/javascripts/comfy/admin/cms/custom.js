// Custom JS for the admin area

if ($('#message_thread_recipients').length) {
  console.log('loading')
  $('select').select2({
    multiple: true,
    required: true,
  })
}
