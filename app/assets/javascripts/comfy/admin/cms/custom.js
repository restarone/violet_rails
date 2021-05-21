// Custom JS for the admin area

let subdomain = /:\/\/([^\/]+)/.exec(window.location.href)[1].split('.')[0]
document.title = `${subdomain} WebAdmin`
if ($('#message_thread_recipients').length) {
  $('select').select2({
    multiple: true,
    required: true,
  })
}