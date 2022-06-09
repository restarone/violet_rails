export default function ctaSuccessHandler() {
  $("form").each(function() {
    $(this).find(':input[type="submit"]').prop('disabled', false);
});
}

export function ctaSuccessHandlerRecaptchaV3(elemId, token) {
  ctaSuccessHandler();

  const element = document.getElementById(elemId);
  element.value = token;
}