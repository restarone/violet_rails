import { Controller } from "@hotwired/stimulus";

/*
 * Usage
 * =====
 *
 * add data-controller="api-namespaces" to the common ancestor that contains Search form, pagination, and table
 *
 * Actions:
 * Add this to "View more" link -> data-action="click->api-namespaces#showPropertiesModal"
 * 
 * Targets:
 * Add this to #propertiesModal -> data-api-namespaces-target="propertiesModal"
*/

export default class extends Controller {
	static targets = ['propertiesModal'];

	showPropertiesModal(e) {
		const dataset = e.target.dataset;
		this.propertiesModalTarget.querySelector('#propertiesModal .modal-subtitle').innerHTML = `Namespace: <a href="/api_namespaces/${dataset.namespaceSlug}">${dataset.namespaceName}</a>`;
		this.propertiesModalTarget.querySelector('#propertiesModal .modal-body-content').textContent = dataset.value;
	}
}