// Custom JS for the admin area


console.log('loading')
if ($('#message_thread_recipients').length) {
  console.log('loading')
  $('select').select2({
    multiple: true,
    required: true,
  })
}