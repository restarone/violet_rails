import { Controller } from "@hotwired/stimulus";
import moment from "moment";
import 'daterangepicker';

export default class extends Controller {
  initialize() {
    $('[data-toggle="tooltip"]').tooltip();

    $('#reportrange').daterangepicker({
        opens: 'left',
        locale: {
          format: 'YYYY/MM/DD'
        },
        startDate: $("#start_date").val() || moment().startOf('month'),
        endDate: $("#end_date").val() || moment().endOf('month'),
        ranges: {
          [moment().format('MMMM YYYY')]: [moment().startOf('month'), moment().endOf('month')],
          '3 months': [moment().startOf('month').subtract(2, 'months'), moment().endOf('month')],
          '6 months': [moment().startOf('month').subtract(5, 'months'), moment().endOf('month')],
          '1 year': [moment().startOf('month').subtract(11, 'months'), moment().endOf('month')]
        }
    }, (start, end, label) => {
      $('#start_date').val(start.format('YYYY-MM-DD'));
      $('#end_date').val(end.format('YYYY-MM-DD'));
      $('#interval').val(label);
      this.cb();
      $("#analytics_filter").submit();
    });
  
    this.cb();
  }

  cb() {
    if (!$('#start_date').val() && !$('#end_date').val()) {
      $('#reportrange span').html(moment().format('MMMM YYYY'));
    } else if ($('#interval').val() == 'Custom Range') {
      $('#reportrange span').html(moment($("#start_date").val()).format('MMMM D, YYYY') + ' - ' + moment($("#end_date").val()).format('MMMM D, YYYY'));
    } else {
      $('#reportrange span').html($('#interval').val());
    }
  }
}