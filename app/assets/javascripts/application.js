//= require 'aaf-lipstick'
//= require 'd3'
//= require 'reporting'
//= require 'render_report'
<<<<<<< 84bf23043d99c60e93c41d1ff7d651618ebd0f6e
//= require jq_validations.js
=======

// TODO
// This code will be moved to jq_validations.js
(function () {
  var validRangeLteq = function(value, element){
    var end_date = $('#report-form #end').val();
    return (Date.parse(value)) <= (Date.parse(end_date));
  };

  var validRangeGteq = function(value, element){
    var start_date = $('#report-form #start').val();
    return (Date.parse(value)) >= (Date.parse(start_date));
  };

  jQuery.validator.addMethod('validRangeLteq', validRangeLteq, null);
  jQuery.validator.addMethod('validRangeGteq', validRangeGteq, null);
}());
>>>>>>> temp
