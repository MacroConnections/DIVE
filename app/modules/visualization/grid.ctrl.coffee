# Parent controller containing data functions
angular.module('diveApp.visualization').controller('GridCtrl', ($scope, DataService, VizDataService, PropertyService, SpecificationService, ConditionalDataService, pIDRetrieved) ->
  # Making resolve data available to directives
  $scope.datasets = []
  $scope.columnAttrsByDID = {}
  $scope.categories = []


  $scope.functions = 
    'count': 'count'
    'sum': 'sum'
    'minimum': 'min'
    'maximum': 'max'
    'average': 'avg'

  # Selected visualization
  $scope.selectedCategory = null
  $scope.selectedType = null
  # Stats showing
  $scope.stats = shown: true
  # Loading
  $scope.loadingViz = false
  # CONDITIONALS
  $scope.condList = []
  $scope.condTypes = {}
  $scope.condData = {}
  $scope.selConds = {}
  # Which are selected to be shown
  $scope.selCondVals = {}
  # Selected values for conditionals
  # Default types given a category
  # TODO Don't put this all in a controller, maybe move to the server side?
  $scope.categoryToDefaultType =
    'time series': 'line'
    'comparison': 'scatter'
    'shares': 'tree_map'
    'distribution': 'bar'
  # TIME SERIES
  $scope.groupOn = []
  # CONFIG
  $scope.config = {}
  $scope.selectedValues = {}
  $scope.selectedParameters =
    x: ''
    y: ''
 
  pIDRetrieved.promise.then (r) ->
    DataService.getDatasets({ pID: $scope.pID }).then (datasets) ->
      $scope.datasets = datasets
      $scope.columnAttrsByDID = {}

      _.each datasets, (e) ->
        # Conditionals for time series visualizations
        if e.structure == 'wide'
          $scope.condList.push name: 'Start Date'
          $scope.condList.push name: 'End Date'
          $scope.condData['Start Date'] = e.time_series.names
          $scope.condData['End Date'] = e.time_series.names
        $scope.columnAttrsByDID[e.dID] = e.column_attrs
        return
      return

    # TODO Find a better way to resolve data dependencies without just making everything synchronous
    PropertyService.getProperties { pID: $scope.pID }, (properties) ->
      $scope.properties = properties
      $scope.overlaps = properties.overlaps
      $scope.hierarchies = properties.hierarchies
      # Getting specifications grouped by category
      SpecificationService.getSpecifications { pID: $scope.pID }, (specs) ->
        $scope.specs = specs
        $scope.categories = _.map(specs, (v, k) ->
          {
            'name': k
            'toggled': true
            'length': v.length
            'specs': v
          }
        )

        _initialSpec = $scope.categories[1].specs[0]
        $scope.selectedVectorY = { name: _initialSpec.groupBy }
        $scope.selectedVectorX = 'share'

  $scope.getVectors = (includeExtras) ->
    _columns = $scope.columnAttrsByDID[$scope.currentdID].slice()

    if includeExtras
      _columns.unshift { name: 'share' }, { name: 'count' }, name: 'time'

    return _columns

  $scope.onSelectVectorY = (vector) ->
    if vector and vector.name isnt $scope.graphedVectorYName
      $scope.selectedVectorY = vector
      _selectedSpec = _.findWhere($scope.specs['shares'], groupBy: $scope.selectedVectorY.name)

      if _selectedSpec
        $scope.selectSpec(_selectedSpec)

    return

  $scope.onSelectVectorX = (vector) ->
    if vector isnt $scope.selectedVectorX
      if vector
        $scope.selectedVectorX = vector
        if vector.name is 'share'
          _visualizationType = 'shares'

        else if vector.name is 'time'
          _visualizationType = 'time series'

        else if vector.name is 'count'
          _visualizationType = 'distribution'

        _selectedSpec = _.findWhere($scope.specs[_visualizationType], groupBy: $scope.selectedVectorY.name)

      else
        _selectedSpec = _.findWhere($scope.specs['shares'], groupBy: $scope.selectedVectorY.name)

      if _selectedSpec
        $scope.selectSpec(_selectedSpec)
    return

  $scope.selectSpec = (spec) ->
    $scope.selectedChild = spec
    $scope.selectedSpec = spec
    $scope.graphedVectorYName = spec.groupBy

    console.log 'SELECTING SPEC', spec.category, $scope.selectedCategory
    # If changing categories, select default type
    if spec.category != $scope.selectedCategory
      $scope.selectedCategory = spec.category
      $scope.selectedType = $scope.categoryToDefaultType[spec.category]
    if spec.aggregate
      dID = spec.aggregate.dID
    else
      dID = spec.object.dID
    $scope.currentdID = dID
    if !$scope.selCondVals[dID]
      $scope.selCondVals[dID] = {}
    colAttrs = $scope.columnAttrsByDID[dID]
    colStatsByName = $scope.properties.stats[dID]
    _.each colAttrs, (c) ->
      $scope.condTypes[c.name] = c.type
      if c.name of colStatsByName
        c.stats = colStatsByName[c.name]
      if !$scope.isNumeric(c.type)
        $scope.condList.push c
      if $scope.isNumeric(c.type)
        $scope.groupOn.push c
      return
    $scope.loadingViz = true
    $scope.refreshVizData()

  # Sidenav data
  $scope.sortFields = [
    {
      property: 'num_elements'
      display: 'Number of Elements'
    }
    {
      property: 'std'
      display: 'Standard Deviation'
    }
  ]
  $scope.sortOrders = [
    {
      property: 1
      display: 'Ascending'
    }
    {
      property: -1
      display: 'Descending'
    }
  ]
  $scope.filters =
    sortField: $scope.sortFields[0].property
    sortOrder: $scope.sortOrders[0].property
  # Watch changes in the configuration
  # TODO Don't run initially
  $scope.$watch('config', ((config) ->
    $scope.refreshVizData()
    return
  ), true)

  $scope.isNumeric = (type) ->
    if type == 'float' or type == 'integer'
      true
    else
      false

  $scope.refreshVizData = ->
    type = $scope.selectedType
    spec = _.omit($scope.selectedSpec, 'stats')
    conditional = $scope.selCondVals
    config = $scope.config
    # Require parameters before refreshing vizData
    if !type or !spec
      return
    $scope.loadingViz = true
    # var filteredSelCondVals = {}
    # _.each($scope.selCondVals, function(v, k) {
    #   if ($scope.selConds[k]) {
    #     filteredSelCondVals[k] = v;
    #   }
    # })

    params = 
      formula:
        aggregate: 
          field: $scope.selectedVectorY
          operation: 'count'
        conditional: []
        query: ''
      pID: $scope.pID

    VizDataService.getVizData(params, (result) ->
      console.log("VizDataResult:", result)
    )
    # params = 
    #   type: type
    #   spec: spec
    #   conditional: conditional
    #   config: config
    #   pID: $scope.pID
    # VizDataService.getVizData params, (result) ->
    #   $scope.vizData = result.result
    #   $scope.vizStats = result.stats
    #   $scope.loadingViz = false
    #   if 'stats' of result
    #     means = result.stats.means
    #     if 'means' of result.stats
    #       selectedValues = {}
    #       sortedMeans = Object.keys(means).sort((a, b) ->
    #         means[b] - (means[a])
    #       )
    #       _.each sortedMeans, (e, i) ->
    #         selectedValues[e] = if i < 10 then true else false
    #        $scope.selectedValues = selectedValues
)