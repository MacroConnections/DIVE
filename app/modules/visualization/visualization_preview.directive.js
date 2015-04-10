var $, d3, d3plus, topojson;

$ = require('jquery');

d3 = require('d3');

d3plus = require('d3plus');

topojson = require('topojson');

require('metrics-graphics')

// MG.convert.date(x, 'date', '%Y-%b')

angular.module('diveApp.visualization').directive("visualizationPreview", [
  "$window", "$timeout", function($window, $timeout) {
    return {
      restrict: "EA",
      scope: {
        vizSpec: "=",
        vizData: "=",
        conditional: "=",
        label: "@",
        onClick: "&"
      },
      link: function(scope, ele, attrs) {
        var renderTimeout;
  
        $window.onresize = function() { scope.$apply(); };

        scope.$watch((function() {
          angular.element($window)[0].innerWidth;
        }), function() {
          scope.render(scope.vizSpec, scope.vizData, scope.conditional);
        });

        scope.$watchCollection("[vizSpec,vizData,conditional]", (function(newData) {
          scope.render(newData[0], newData[1], newData[2]);
        }), true);

        return scope.render = function(vizSpec, vizData, conditional) {
          if (!(vizSpec && vizData && conditional)) { return; }
          if (renderTimeout) { clearTimeout(renderTimeout); }

          console.log("VIZDATA", vizData)

          return renderTimeout = $timeout(function() {
            var agg, condition, d3PlusTypeMapping, dropdown, getTitle, viz, x, y;

            var vizType = vizSpec.viz_type;

            getTitle = function(vizType, vizSpec, conditional) {
              var title;
              title = '';
              if (vizType === 'treemap' || vizType === 'piechart') {
                title += 'Group all ' + vizSpec.aggregate.title + ' by ' + vizSpec.groupBy.title.toString();
                if (vizSpec.condition.title) {
                  title += ' given a ' + vizSpec.condition.title.toString();
                }
              } else if (vizType === 'scatterplot' || vizType === 'barchart' || vizType === 'linechart') {
                return;
              }
              return title;
            };
            if (condition) {
              condition = vizSpec.condition.title.toString();
              if (conditionalData.length < 300) {
                dropdown = d3plus.form().container("div#viz-container").data(conditionalData).title("Select Options").id(condition).text(condition).type("drop").title(condition).draw();
              }
            }

            if (vizType === 'time series') {

              var width = $(".visualization").width();
              var height = $("#viz-container").height();

              var timeSeriesMatrix = [];
              var legend = [];

              for (var k in vizData) {
                legend.push(k);
                timeSeriesMatrix.push(MG.convert.date(vizData[k], 'date', '%Y-%b'));
              }
              MG.data_graphic({
                data: timeSeriesMatrix,
                target: '#viz-container',
                x_accessor: 'date',
                y_accessor: 'value',
                xax_count: 12,
                y_extended_ticks: true,
                aggregate_rollover: true,
                interpolate_tension: 0.9,
                show_rollover_text: true,
                max_data_size: 10,
                legend: legend,
                legend_target: '.legend',
                width: width,
                height: height
                // width: width,
                // height: height
              })
            } else {
              viz = d3plus.viz().title(getTitle(vizType, vizSpec)).type(d3PlusTypeMapping[vizType]).container("div#viz-container").width($("div#viz-container").width() - 40).margin("20px").height(600).data(vizData).font({
                family: "Titillium Web"
              });
            }

            d3PlusTypeMapping = {
              treemap: 'tree_map',
              piechart: 'pie',
              barchart: 'bar',
              scatterplot: 'scatter',
              linechart: 'line',
              geomap: 'geo_map'
            };

            
            if (vizType === "treemap" || vizType === "piechart") {
              return viz.id(vizSpec.groupBy.title.toString()).size("count").draw();
            } else if (vizType === "scatterplot" || vizType === "barchart" || vizType === "linechart") {
              x = vizSpec.x.title;
              agg = vizSpec.aggregation;
              if (agg) {
                console.log(x);
                viz.x(x).y("count");
                if (vizSpec.x.type === "datetime") {
                  viz.x(function(d) {
                    return (new Date(d[x])).valueOf();
                  }).format({
                    number: function(d, k) {
                      if (typeof k === "function") {
                        return d3.time.format("%m/%Y")(new Date(d));
                      } else {
                        return d;
                      }
                    }
                  }).y("count");
                } else {
                  viz.x(x).y("count");
                }
                if (vizType === "linechart") {
                  return viz.id("id").draw();
                } else {
                  return viz.id(x).size(10).draw();
                }
              } else {
                y = vizSpec.y.title;
                return viz.title(getTitle(vizType, vizSpec)).x(x).y(y).id(x).draw();
              }
            } else if (vizType === "geomap") {
              console.log("Rendering geomap with id:", vizSpec.groupBy.title.toString());
              return viz.title(getTitle(vizType, vizSpec)).coords("/assets/misc/countries.json").id("id").text("label").color("count").size("count").draw();
            }
          }, 200);
        };
      }
    };
  }
]);

// ---
// generated by coffee-script 1.9.0