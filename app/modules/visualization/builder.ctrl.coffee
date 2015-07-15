angular.module('diveApp.visualization').controller('BuilderCtrl', ($scope, $rootScope, DataService, PropertyService, VisualizationDataService, pIDRetrieved) ->

  @COUNT_ATTRIBUTE =
    label: "count"
    type: "int"
    unique: true

  @ATTRIBUTE_TYPES =
    NUMERIC: ["int", "float"]

  # UI Parameters
  @AGGREGATION_FUNCTIONS = [
    title: 'sum'
    value: 'sum'
  , 
    title: 'minimum'
    value: 'min'
  ,
    title: 'maximum'
    value: 'max'
  , 
    title: 'average'
    value: 'mean'
  ]

  @OPERATORS = [
    title: '=' 
    value: '=='
  , 
    title: '≠'
    value: '!='
  , 
    title: '>'
    value: '>'
  ,
    title: '≥'
    value: '>='
  , 
    title: '<'
    value: '<'
  ,
    title: '<='
    value: '≤'
  ]

  @OPERATIONS = [
    title: 'grouped on'
    value: 'group'
  ,
    title: 'vs'
    value: 'vs'
  ,
    title: 'compare'
    value: 'compare'
  ]

  @availableOperations = @OPERATIONS
  @availableAggregationFunctions = @AGGREGATION_FUNCTIONS

  @selectedDataset = null

  @selectedParams =
    dID: ''
    field_a: ''
    operation: @OPERATIONS[0].value
    arguments:
      field_b: @COUNT_ATTRIBUTE.label
      function: @AGGREGATION_FUNCTIONS[0].value

  @attributeB = @COUNT_ATTRIBUTE

  @selectedConditional =
    'and': []
    'or': []

  @isGrouping = false

  @onSelectDataset = (d) ->
    @setDataset(d)
    return

  @setDataset = (d) ->
    @selectedDataset = d
    @selectedParams.dID = d.dID

    @retrieveProperties()
    return

  @onSelectAggregationFunction = (fn) ->
    @selectedFunction = fn
    console.log("Selected Function", fn)
    @refreshVisualization()

  @onSelectOperator = (op) ->
    @selectedOperation = op
    console.log("Selected Operation", op)

  @refreshVisualization = () ->
    if @attributeA and @attributeB
      _params =
        spec: @selectedParams
        conditional: @selectedConditional

      VisualizationDataService.getVisualizationData(_params).then((data) =>
        @visualizationData = data.viz_data
        @tableData = data.table_result
      )

  @onSelectFieldA = () ->
    @selectedParams['field_a'] = @attributeA.label

    @refreshOperations()
    @refreshVisualization()
    return

  @onSelectFieldB = () ->
    @selectedParams.arguments['field_b'] = @attributeB.label
    @refreshVisualization()
    return

  @refreshOperations = () ->
    if @attributeA and (@attributeA.type in @ATTRIBUTE_TYPES.NUMERIC or @attributeA.unique)
      @availableOperations = _.reject(@OPERATIONS, (operation) -> operation.value is "group")

      if @selectedParams.operation is "group"
        @selectedParams.operation = @availableOperations[0].value

      @attributeB = undefined

    @isGrouping = @selectedParams.operation is "group"
    return

  @getAttributes = (type = {}) ->
    if @properties
      _attr = @properties.slice()

      if type.primary
        _attr = _.reject(_attr, (property) => property.type in @ATTRIBUTE_TYPES.NUMERIC)

      if type.secondary
        _attr = _.reject(_attr, (property) => property.label is @selectedParams.field_a)

        if @isGrouping
          _attr = _.filter(_attr, (property) => property.type in @ATTRIBUTE_TYPES.NUMERIC)

        _attr.unshift(@COUNT_ATTRIBUTE)

    return _attr

  @datasetsLoaded = false
  @propertiesLoaded = false

  @retrieveProperties = () ->
    PropertyService.getProperties({ pID: $rootScope.pID, dID: @selectedDataset.dID }).then((properties) =>
      @propertiesLoaded = true
      @properties = properties
    )
    return

  pIDRetrieved.promise.then((r) =>
    DataService.getDatasets().then((datasets) =>
      @datasetsLoaded = true
      @datasets = datasets
      @setDataset(datasets[0])
      console.log("Datasets loaded!", @datasets)
    )
  )

  @
)