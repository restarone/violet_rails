window.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#checkout_form_payment');
  const existingCards = document.querySelector('#existing_cards');

  if (form) {
    if (existingCards) {
      const paymentMethodControls = document.querySelector('.payment-method-controls');
      const useExistingCardYes = document.querySelector('#use_existing_card_yes');
      const useExistingCardNo = document.querySelector('#use_existing_card_no');
      const existingCcRadios = document.querySelectorAll('.existing-cc-radio');

      paymentMethodControls.style.display = 'none';

      useExistingCardYes.addEventListener('click', () => {
        paymentMethodControls.style.display = 'none';
        existingCcRadios.forEach(radio => radio.removeAttribute('disabled'));
      });

      useExistingCardNo.addEventListener('click', () => {
        paymentMethodControls.style.display = 'block';
        existingCcRadios.forEach(radio => radio.setAttribute('disabled', true));
      });
    }

    const selectors = document
      .querySelectorAll('input[type="radio"][name="order[payments_attributes][][payment_method_id]"]');

    selectors.forEach(selector => {
      selector.addEventListener('click', () => {
        const controls = document.querySelectorAll('.payment-method-controls li');
        controls.forEach(control => control.style.display = 'none');

        if (selector.checked) {
          const selectedControl = document.querySelector(`#payment_method_${selector.value}`);
          selectedControl.style.display = 'block';
        }
      });
    });

    // Activate already checked payment method if form is re-rendered
    // i.e. if user enters invalid data
    document.querySelector('input[type="radio"]:checked').click();
  }
});
