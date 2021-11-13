window.addEventListener('DOMContentLoaded', (event) => {
  console.log('DOM fully loaded and parsed');
  if ($('#message_thread_recipients').length) {
    console.log('loading')
    $('select').select2({
      multiple: true,
      required: true,
    })
  }
});

console.log('ss')