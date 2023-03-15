import moment from "moment";
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-form"
export default class extends Controller {
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

    $(this.element).on("input", (_event, _params) => {
      this.search();
    });
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 200)
  }

  clearText() {
    const searchField = this.element.querySelector("input[type='search']")
    searchField.value = ""
    this.element.requestSubmit();
  }
}