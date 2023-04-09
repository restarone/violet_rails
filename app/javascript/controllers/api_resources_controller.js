import { Controller } from "@hotwired/stimulus";
import moment from "moment";
import 'daterangepicker';

/*
 * Usage
 * =====
 *
 * add data-controller="api-resources" to the common ancestor that contains Search form, pagination, and table
 *
 * Actions:
 * Add this to "View <property_name>" link -> data-action="click->api-resources#showModal"
 *
 * Targets:
 * Add this to #myModal -> data-api-resources-target="modal"
*/

export default class extends Controller {
  static targets = ['modal']

  ranges = {
    'Last 7 days': [moment().subtract(6, 'days'), moment()],
    'Last 30 days': [moment().subtract(29, 'days'), moment()],
    'Last 3 months': [moment().subtract(2, 'months').startOf('month'), moment().endOf('month')],
    'Last 12 months': [moment().subtract(11, 'months').startOf('month'), moment().endOf('month')],
    'Month to date': [moment().startOf('month'), moment()],
    'Quarter to date': [moment().startOf('quarter'), moment()],
    'All time': [moment().subtract(20, 'years'), moment()]
  }

  initialize() {
    $('#created-at-filter').daterangepicker({
      opens: 'left',
      locale: {
        format: 'YYYY/MM/DD'
      },
      startDate: $("#q_created_at_gteq").val() || moment().subtract(20, 'years').endOf('day'),
      endDate: $("#q_created_at_end_of_day_lteq").val() || moment().endOf('day'),
      ranges: this.ranges,
    }, function(start, end, label) {
      $('#q_created_at_gteq').val(start.format('YYYY-MM-DD'));
      $('#q_created_at_end_of_day_lteq').val(end.format('YYYY-MM-DD')).trigger("input");
    });

    $('#updated-at-filter').daterangepicker({
      opens: 'left',
      locale: {
        format: 'YYYY/MM/DD'
      },
      startDate: $("#q_updated_at_gteq").val() || moment().subtract(20, 'years').endOf('day'),
      endDate: $("#q_updated_at_end_of_day_lteq").val() || moment().endOf('day'),
      ranges: this.ranges,
    }, function(start, end, label) {
      $('#q_updated_at_gteq').val(start.format('YYYY-MM-DD'));
      $('#q_updated_at_end_of_day_lteq').val(end.format('YYYY-MM-DD')).trigger("input");
    });
  }

  showModal(e) {
    const dataset = e.target.dataset;
    this.modalTarget.querySelector('#myModalLabel').textContent = dataset['column'];
    this.modalTarget.querySelector('#myModal .modal-subtitle').innerHTML = `ID: <a href="/api_namespaces/${dataset['namespaceId']}/resources/${dataset['id']}">${dataset['id']}</a>`;
    this.modalTarget.querySelector('#myModal .modal-body-content').textContent = dataset['value'];
  }
}