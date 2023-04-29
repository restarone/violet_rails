// Custom JS for the admin area

// patch the correct subdomain admin name in the browser tab

//= require select2

var subdomain = /:\/\/([^\/]+)/.exec(window.location.href)[1].split('.')[0]
document.title = `${subdomain} Admin`

// when html body is clicked collapse bootstrap nav expansion
$(document).click(function (event) {
  let clickover = $(event.target);
  let _opened = $(".navbar-collapse").hasClass("navbar-collapse collapse show");
  if (_opened === true && !clickover.hasClass("navbar-toggler")) {
    $("button.navbar-toggler").click();
  }
});

if ($('#message_thread_recipients').length) {
  $('select').select2({
    multiple: true,
    required: true,
  })
}