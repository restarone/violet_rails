export default function ctaSuccessHandler() {
  $("form").each(function() {
    $(this).find(':input[type="submit"]').prop('disabled', false);
});
}

export function ctaSuccessHandlerRecaptchaV3(elemId, token) {
  ctaSuccessHandler();

  // By default recaptcha calls method: setInputWithRecaptchaResponseTokenFor#{sanitize_action(action)} as callback which sets the value of hidden input to the token.
  const element = document.getElementById(elemId);
  element.value = token;
}