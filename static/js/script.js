var app;

window.SC = function(selector) {
  return angular.element(selector).scope();
};

app = angular.module('app', []);

app.config(function($interpolateProvider) {
  return $interpolateProvider.startSymbol('{[{').endSymbol('}]}');
});

app.controller('DatasetListCtrl', function($scope, $http) {
  window.onload = function() {
    var files;

    $('#data-file').on('change', function(event) {
      files = event.target.files;
    });

    $('#data-submit').click(function(event) {
      var data = new FormData();
      data.append('dataset', files[0])

      $.ajax({
        url: '/upload',
        type: 'POST',
        data: data,
        cache: false,
        processData: false,
        contentType: false,
      }).success(function(data) {
        if (data.status === "success") {
          delete data['status'];

          // update model with file data
          $scope.$apply(function() {
            data.title = data.filename;
            $scope.datasets.push(data);
          });
        }
      });
    });
  };

  $scope.datasets = [
    {
      title: "Dataset 1",
      rows: 100,
      cols: 1000,
      type: "CSV"
    }, {
      title: "Dataset 2",
      rows: 150,
      cols: 1500,
      type: "TSV"
    }
  ];

  return console.log($scope);
});
