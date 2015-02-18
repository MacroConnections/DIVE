angular.module("diveApp.data").controller "DatasetListCtrl", ($scope, $rootScope, projectID, $http, $upload, $timeout, $stateParams, DataService, API_URL) ->
  $scope.selectedIndex = 0
  $scope.currentPane = 'left'

  $scope.datasets = []

  $scope.options = [
    {
      label: 'Upload File'
      inactive: false
      icon: 'file.svg'
    },
    # {
    #   label: 'Connect to Database'
    #   inactive: true
    #   icon: 'database.svg'
    # },
    # {
    #   label: 'Connect to API'
    #   inactive: true
    #   icon: 'link.svg'
    # },
    {
      label: 'Search DIVE Datasets'
      inactive: false
      icon: 'search.svg'
    }
  ]
  $scope.select_option = (index) ->
    $scope.currentPane = 'left'
    # Inactive options (for demo purposes)
    unless $scope.options[index].inactive
      $scope.selectedIndex = index

  $scope.select_dataset = (index) ->
    $scope.currentPane = 'right'
    $scope.selectedIndex = index

  $scope.types = [ "integer", "float", "string", "countryCode2", "countryCode3", "countryName", "continent", "datetime" ]

  # Initialize datasets
  DataService.promise((datasets) ->
    $scope.datasets = datasets
    console.log($scope.datasets)
  )

  ###############
  # Dataset Structure
  ###############
  $scope.structures = [
    {
      name: 'long'
      displayName: 'Long (Record or stacked format)'
    },
    {
      name: 'wide'
      displayName: 'Wide (Matrix-like)'
    }
  ]

  $scope.selectedStructure = (structure) ->
    datasetStructure = $scope.datasets[$scope.selectedIndex].structure 
    if structure is datasetStructure then true else false

  $scope.selectStructure = (structure) ->
    $scope.datasets[$scope.selectedIndex].structure = structure

  ###############
  # File Upload
  ###############
  $scope.onFileSelect = ($files) ->
    i = 0
    while i < $files.length
      file = $files[i]
      $scope.upload = $upload.upload(
        url: API_URL + "/api/upload"
        data:
          pID: $rootScope.pID
        file: file
      ).progress((evt) ->
        console.log "Percent loaded: " + parseInt(100.0 * evt.loaded / evt.total)
        return
      ).success((data, status, headers, config) ->
        # file is uploaded successfully
        for dataset in data.datasets
          $scope.datasets.push(dataset)
        console.log $scope.datasets
      )
      i++
  ###############
  # File Deletion
  ###############
  $scope.removeDataset = (dID) ->
    console.log('Removing dataset, dID:', dID)
    $http.delete(API_URL + '/api/data',
      params:
        pID: $rootScope.pID
        dID: dID
    ).success((result) ->
      deleted_dIDs = result
      newDatasets = []
      for dataset in $scope.datasets
        unless dataset.dID in deleted_dIDs
          newDatasets.push(dataset)
      $scope.datasets = newDatasets
    )
