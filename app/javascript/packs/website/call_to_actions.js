export default function ctaSuccessHandler() {
  $("form").each(function() {
    $(this).find(':input[type="submit"]').prop('disabled', false);
});
}