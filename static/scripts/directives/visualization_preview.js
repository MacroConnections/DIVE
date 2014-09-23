engineApp.directive("visualizationPreview", [
  "$window", "$timeout", "d3Service", function($window, $timeout, d3Service) {
    return {
      restrict: "EA",
      scope: {
        vizType: "=",
        vizSpec: "=",
        vizData: "=",
        label: "@",
        onClick: "&"
      },
      link: function(scope, ele, attrs) {
        d3Service.d3().then(function(d3) {
          var renderTimeout;
          renderTimeout = void 0;
          $window.onresize = function() {
            scope.$apply();
          };
          scope.$watch((function() {
            return angular.element($window)[0].innerWidth;
          }), function() {
            scope.render(scope.vizType, scope.vizSpec, scope.vizData);
          });
          scope.$watchCollection("[vizType,vizSpec,vizData]", (function(newData) {
            scope.render(newData[0], newData[1], newData[2]);
          }), true);
          scope.render = function(vizType, vizSpec, vizData) {
            console.log(vizType, vizSpec, vizData);
            if (!(vizData && vizSpec && vizType)) {
              return;
            }
            if (renderTimeout) {
              clearTimeout(renderTimeout);
            }
            renderTimeout = $timeout(function() {
              var dropdown, groupBy, selectData, viz;
              console.log(vizData, vizSpec);
              groupBy = vizSpec.groupBy.title.toString();
              selectData = [
                {
                  value: "ar",
                  text: "Arabic"
                }, {
                  value: "zh",
                  text: "Chinese"
                }, {
                  value: "en",
                  text: "English",
                  selected: true
                }, {
                  value: "de",
                  text: "German"
                }, {
                  value: "pt",
                  text: "Portuguese"
                }, {
                  value: "es",
                  text: "Spanish"
                }
              ];
              if (vizType === "treemap") {
                console.log('drawing treemap');
                viz = d3plus.viz().container("div#viz-container").data(vizData).type("tree_map").font({
                  family: "Karbon"
                }).id(groupBy).size("count").draw();
                dropdown = d3plus.form().container("div#viz-container").data(selectData).title("Select Options").draw();
              } else if (vizType === "geomap") {
                viz = d3plus.viz().container("div#viz-container").type("geo_map").data(vizData).coords("/static/assets/countries.json").id(groupBy).color("count").text("name").font({
                  family: "Karbon"
                }).style({
                  color: {
                    heatmap: ["grey", "purple"]
                  }
                }).draw();
              }
            }, 200);
          };
        });
      }
    };
  }
]);
