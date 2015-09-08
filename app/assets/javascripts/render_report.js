jQuery(function($) {
  var renderReport = function(report) {
    var sizing = reporting.sizing(report);

    var svg = d3.select('svg' + reporting.selector)
      .attr('class', report.type)
      .attr('height', sizing.container.height)
      .attr('width', sizing.container.width);

    svg.selectAll('svg > *').remove();

    var range = reporting.range(report);
    var scale = reporting.scale(report, range, sizing);
    var translate = reporting.translate;
    var graph = sizing.graph;
    var margin = graph.margin;

    var mappers = {
      x: function(e) { return scale.x(d3.time.second.offset(range.start, e[0])); },
      y: function(e) { return scale.y(e[1]); }
    };

    var charts = {
      generic: function(type, d) {
        var g = svg.append('g')
          .attr('class', type + ' paths')
          .call(translate(margin.left, margin.top))

        report.series.forEach(function(key) {
          g.append('path')
            .datum(report.data[key])
            .attr('class', key)
            .attr('d', d);
        });

        svg.call(reporting.axes(scale, sizing))
          .call(reporting.legend(report, sizing))
          .call(reporting.hoverbox(report, scale, range, sizing))
          .call(reporting.labels(report, range, sizing));
      },

      area: function() {
        var area = d3.svg.area()
          .x(mappers.x)
          .y0(graph.height)
          .y1(mappers.y);

        charts.generic('area', area);
      },

      line: function() {
        var line = d3.svg.line()
          .x(mappers.x)
          .y(mappers.y);

        charts.generic('line', line);
      }
    };

    charts.line();
  };

  var json = $('#report-data').html();
  if (json) {
    var data = $.parseJSON(json);

    d3.select(window).on('resize', reporting.throttle(function() {
      renderReport(data);
    }, 250));

    setTimeout(function() { renderReport(data); }, 0);
  }
});
