// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require bootstrap-sprockets
//= require jquery3
//= require popper
//= require lodash
//= require tablesort
//= require tablesort/dist/sorts/tablesort.number.min
//= require bs-custom-file-input

// TODO: load these selectively as necessary
//= require teleconsultation-fields

//= require_tree .

$(function () {
  // initialize tooltips via bootstrap (uses popper underneath)
  $('[data-toggle="tooltip"]').tooltip()

  // initialize tablesort on analytics dashboard table
  if($('#analytics-table').length) {
    new Tablesort(document.getElementById('analytics-table'), { descending: true })
  }

  // initialize bootstrap file input
  bsCustomFileInput.init();
});
