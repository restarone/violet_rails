import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ['searchForm', 'propertiesModal'];

	showPropertiesModal(e) {
		const dataset = e.target.dataset;
		this.propertiesModalTarget.querySelector('#propertiesModal .modal-subtitle').innerHTML = `Namespace: <a href="/api_namespaces/${dataset.namespaceSlug}">${dataset.namespaceName}</a>`;
		this.propertiesModalTarget.querySelector('#propertiesModal .modal-body-content').textContent = dataset.value;
	}

	clearSearch() {
		const searchInput = this.searchFormTarget.querySelector('input[type="search"]');
		searchInput.value = "";
	}

	reloadTable() {
    const tableRows = document.querySelectorAll(".list-view tbody tr");
    const params = new URLSearchParams(location.search);
    // preserve page and sort order number while submitting form
    if (params.get('page')) {
      const pageNumber = getVerifiedPageNumber();
      $(this.searchFormTarget).append(`<input type="hidden" name="page" value="${pageNumber}" />`);
    }

    if (params.get('q[s]')) {
      $(this.searchFormTarget).append(`<input type="hidden" name="q[s]" value="${params.get('q[s]')}" />`);
    }
    this.searchFormTarget.requestSubmit();

    this.searchFormTarget.querySelector('input[name="page"]')?.remove();
    this.searchFormTarget.querySelector('input[name="q[s]"]')?.remove();

    function getVerifiedPageNumber() {
      const pageNumber = Number.parseFloat(params.get('page'));
      // if the page number is greater than 1 and there is one remaining table row, then go to the previous page
      // because after deletion, there will be no table row on this page
      if (pageNumber > 1 && tableRows.length == 1) return (pageNumber - 1).toString();
      return pageNumber.toString();
    }
  }
}