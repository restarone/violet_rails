import { Controller } from "@hotwired/stimulus";

/*
 * Usage
 * =====
 *
 * add data-controller="list-view" to the common ancestor that contains Search form, pagination, and table
 *
 * Actions:
 * Add this to the Delete icon link data-action="ajax:success->list-view#reloadTable"
 *
 * Targets:
 * Add this to Search form -> data-list-view-target="searchForm"
 *
 * Enabling instant search
 * Add class "list-view--instant-search" to the element having data-controller="list-view"
 * Add data-instant-search-mode="true" to the Search form
*/

export default class extends Controller {
  static targets = ["searchForm"];

  initialize() {
    const instantSearchMode = this.searchFormTarget.dataset.instantSearchMode;
    if (instantSearchMode == "true") {
      $(this.searchFormTarget).on("input", (_event, _params) => {
        this.instantSearch();
      });
    } else {
      // Submit the form when the user clicks on 'X' icon in the search input box
      // Clear search results and show all list items when the user clicks on 'X' icon
      $(this.searchFormTarget).on("input", (_event, _params) => {
        if (_event.target.value == "") this.searchFormTarget.requestSubmit();
      });
    }
  }

  instantSearch() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.searchFormTarget.requestSubmit();
    }, 200);
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