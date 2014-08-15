controllers = angular.module("engineControllers", [])

# Landing page project list / navigation
controllers.controller "ProjectListCtrl", ($scope, $http) ->
  $scope.user = {
    userName: 'demo-user'
    displayName: 'Demo User'
  }
  $scope.projects = [
    { title: 'Culture', displayTitle: 'culture' },
    { title: 'Healthcare', displayTitle: 'healthcare' },
    { title: 'Consumer Analysis', displayTitle: 'consumer-analysis' },
  ]   

  $scope.select_project = (id) ->
    console.log(id)

  $scope.new_project = ->
    $http(
      method: 'POST'
      url: 'http://localhost:8888/api/project'
      transformRequest: objectToQueryString
      headers: {'Content-Type': 'application/x-www-form-urlencoded'}
    ).success((data) ->
      console.log("Successful request")
    )

controllers.controller "PaneToggleCtrl", ($scope) ->
  $scope.leftClosed = false
  $scope.rightClosed = false
  $scope.toggleLeft = -> $scope.leftClosed = !$scope.leftClosed
  $scope.toggleRight = -> $scope.rightClosed = !$scope.rightClosed

# Stateful navigation (tabs)
controllers.controller "TabsCtrl", ($scope, $routeParams) ->
  $scope.uID = $routeParams.uID
  $scope.pID = $routeParams.pID
  $scope.tabs = [
    {
      link: "data"
      label: "1. Manage Datasets"
    }
    {
      link: "ontology"
      label: "2. Edit Ontology"
    }
    {
      link: "visualize"
      label: "3. Select Visualizations"
    }
    {
      link: "assemble"
      label: "4. Assemble Engine"
    }
  ]
  # TODO Tie this into router
  $scope.selectedTab = $scope.tabs[0]
  $scope.setSelectedTab = (tab) ->
    $scope.selectedTab = tab

  $scope.tabClass = (tab) ->
    if $scope.selectedTab is tab then "active"
    else ""

controllers.controller "DatasetListCtrl", ($scope, $http, DataService) ->
  files = undefined
  $("#data-file").on "change", (event) ->
    files = event.target.files
    return

  $("#data-submit").click (event) ->
    data = new FormData()
    data.append "dataset", files[0]
    $.ajax(
      url: "/upload"
      type: "POST"
      data: data
      cache: false
      processData: false
      contentType: false
    ).success (data) ->
      if data.status is "success"
        delete data["status"]

        
        # update model with file data
        $scope.$apply ->
          data.title = data.filename
          data.colAttrs = []
          i = 0

          while i < data.cols
            data.colAttrs[i] =
              name: data.header[i]
              type: data.types[i]
            i++
          delete data["header"]

          delete data["types"]

          $scope.datasets.push data
          return

      return

    return

  $scope.selected_index = 0
  $scope.select_dataset = (index) ->
    $scope.selected_index = index
    return

  $scope.types = [
    "int"
    "float"
    "str"
  ]
  
  # Initialize datasets
  $scope.datasets = DataService.getData()
  return


# TODO Make this controller thin
controllers.controller "OntologyEditorCtrl", ($scope, $http, DataService, OverlapService) ->
  
  # Initialize datasets
  $scope.datasets = DataService.getData()
  
  # Get non-zero overlaps between columns
  relnData = OverlapService.getData()
  $scope.overlaps = relnData.overlaps
  $scope.hierarchies = relnData.hierarchies
  return

controllers.controller "AssembleCtrl", ($scope, $http) ->
  return

# TODO Make this controller thinner!
controllers.controller "CreateVizCtrl", ($scope, $http, DataService, OverlapService, VizDataService, VizFromOntologyService) ->
  
  # Initialize datasets
  datasets = DataService.getData()
  $scope.datasets = datasets
  relnData = OverlapService.getData()
  
  # TODO Watch changes and propagate changes
  nodes = []
  edges = []
  
  # Populate nodes
  i = 0

  while i < datasets.length
    dataset = datasets[i]
    node =
      model: dataset.dataset_id
      attrs: dataset.column_attrs
      unique_cols: dataset.unique_cols

    nodes.push node
    i++
  for datasetPair of relnData.hierarchies
    hierarchy = relnData.hierarchies[datasetPair]
    datasetPairList = datasetPair.split("\t")
    for columnPair of hierarchy
      type = hierarchy[columnPair]
      columnPairList = columnPair.split("\t")
      d = relnData.overlaps[datasetPair][columnPair]
      if d > 0.5
        
        # Only add edge if overlap
        edge =
          source: [
            parseInt(datasetPairList[0])
            parseInt(columnPairList[1])
          ]
          target: [
            parseInt(datasetPairList[1])
            parseInt(columnPairList[1])
          ]
          type: type

        edges.push edge
  initNetwork =
    nodes: nodes
    edges: edges

  
  # TODO Pare down this UI stuff
  $scope.initNetwork = initNetwork
  
  # TODO Don't be redundant
  $scope.vizType = "treemap"
  $scope.selected_vizType_index = 1
  $scope.select_vizType = (index) ->
    $scope.vizType = $scope.vizTypes[index].name
    $scope.selected_vizType_index = index
    
    # TODO: There must be a better way to do pretty much an ng-if on an object
    $scope.vizSpecs = $scope.allVizSpecs[$scope.selected_vizType]
    return

  $scope.selected_vizSpec_index = 0
  $scope.select_vizSpec = (index) ->
    $scope.selected_vizSpec_index = index
    return
  
  # TODO Abstract these to a global client-side ID reference
  $scope.getDatasetTitle = (dataset_id) ->
    datasets[dataset_id].title

  $scope.getColumnName = (dataset_id, column_id) ->
    datasets[dataset_id].column_attrs[column_id].name

  
  # Correct way to handle argument passing to async service
  $scope.vizFromOntology = ->
    
    # TODO Move parsing logic to server side...or just have it in the correct format anyways
    VizFromOntologyService.promise $scope.initNetwork, (data) ->
      visualizations = data.visualizations
      vizTypes = []
      for visualization of visualizations
        vizTypes.push
          name: visualization
          count: visualizations[visualization].length

      $scope.vizTypes = vizTypes
      $scope.vizSpecs = visualizations[$scope.vizType]
      $scope.allVizSpecs = visualizations
      return

    return

  $scope.vizFromOntology()
  $scope.setVizData = (vizSpec) ->
    $scope.vizSpec = vizSpec
    VizDataService.promise vizSpec, (result) ->
      $scope.vizData = result.result
      return

    return

  return
