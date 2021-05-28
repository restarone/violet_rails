export default function ctaSuccessHandler() {
  $(".violet-cta-form").each(function() {
    $(this).find(':input[type="submit"]').prop('disabled', false);
});
}