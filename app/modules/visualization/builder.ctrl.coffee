angular.module('diveApp.visualization').controller('BuilderCtrl', ($scope, $rootScope, DataService, PropertiesService, VisualizationDataService, VizSpecService, pIDRetrieved) ->

  @ATTRIBUTE_TYPES =
    NUMERIC: ["int", "float"]

  # UI Parameters
  @AGGREGATION_FUNCTIONS = [
      title: 'count'
      value: 'count'
    ,
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

  @VISUALIZATION_TYPES =
    TREEMAP: 'tree_map'
    BAR: 'bar'
    PIE: 'pie'
    LINE: 'line'
    SCATTERPLOT: 'scatter'

  @VISUALIZATION_TYPE_DATA = [
      label: 'Treemap'
      type: @VISUALIZATION_TYPES.TREEMAP
      icon: '/assets/images/charts/treemap.chart.svg'
    ,
      label: 'Bar Graph'
      type: @VISUALIZATION_TYPES.BAR
      icon: '/assets/images/charts/bar.chart.svg'
    ,
      label: 'Pie Graph'
      type: @VISUALIZATION_TYPES.PIE
      icon: '/assets/images/charts/pie.chart.svg'
    ,
      label: 'Line Graph'
      type: @VISUALIZATION_TYPES.LINE
      icon: '/assets/images/charts/line.chart.svg'
    ,
      label: 'Scatterplot'
      type: @VISUALIZATION_TYPES.SCATTERPLOT
      icon: '/assets/images/charts/scatterplot.chart.svg'
      disabled: true
  ]

  @OPERATORS = {
    NUMERIC: [
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
        title: '≤'
        value: '<='
    ]

    DISCRETE: [
        title: '='
        value: '=='
      ,
        title: '≠'
        value: '!='
    ]

  }

  @OPERATIONS = {
    UNIQUE: [
        title: 'vs'
        value: 'vs'
      ,
        title: 'compare'
        value: 'compare'
    ]

    NON_UNIQUE: [
        title: 'grouped by'
        value: 'group'
      ,
        title: 'compare'
        value: 'compare'
    ]
  }

  @ALL_TIME_ATTRIBUTE = {
    label: "All Time"
    type: "string"
    child: []
  }

  @availableAggregationFunctions = @AGGREGATION_FUNCTIONS
  @conditional1IsNumeric = true

  @selectedDataset = null

  @selectedChildEntities = {}

  @selectedConditional =
    'and': []
    'or': []

  @conditional1 =
    field: null
    operation: null
    criteria: null

  @isGrouping = false

  @resetParams = () ->
    @availableOperators = @OPERATORS.NUMERIC
    @availableOperations = @OPERATIONS.NON_UNIQUE
    @availableVisualizationTypes = _.pluck(@VISUALIZATION_TYPE_DATA, 'type')
    @selectedVisualizationType = null

    @selectedParams =
      dID: ''

    @resetDIDParams()
    return

  @resetDIDParams = ->
    @selectedParams['field_a'] = ''
    @selectedParams['operation'] = @OPERATIONS.NON_UNIQUE[0].value
    @selectedParams['arguments'] =
      field_b: ''
      function: ''

    @selectedEntityLabel = null

    @attributeA = ' ' # the autocomplete field doesn't refresh if attributeA is null or ''
    @attributeB = null
    @resetIsGrouping()
    return

  @selectEntityDropdown = (entityName) ->
    @menu = $($(".md-select-menu-container[ng-data-entity='#{entityName}']")[0])
    _button = $($(".radio-button[ng-data-entity='#{entityName}']")[0])

    @menu.css('top', _button.offset().top + _button.height())
    @menu.css('left', _button.offset().left)
    @menu.remove()

    @backdrop = $('<md-backdrop class="md-select-backdrop md-click-catcher md-default-theme"></md-backdrop>')
    @backdrop.one('click', $.proxy(@closeMenu, @))

    $(document.body).append(@backdrop)
    $(document.body).append(@menu)
    @menu.css('display', 'block')
    @menu.addClass('md-active')
    return

  @closeMenu = () ->
    @menu?.removeClass('md-active')
    @menu?.css('display', 'none')
    @backdrop?.remove()

  @onSelectDataset = (d) ->
    @setDataset(d)
    return

  @setDataset = (d) ->
    @resetParams()

    @selectedDataset = d
    @selectedParams.dID = d.dID


    @retrieveProperties()
    return

  @resetIsGrouping = () ->
    @isGrouping = @selectedParams.operation is "group"
    if @isGrouping
      @selectedParams.arguments.function = @availableAggregationFunctions[0].value
    else
      @selectedParams.arguments.function = null
    return

  @onSelectOperation = () ->
    @resetIsGrouping()
    return

  @onSelectAggregationFunction = () ->
    if @selectedParams.arguments.function is "count"
      @selectedParams.arguments.field_b = null
      @attributeB = null

    @refreshVisualization()

  @onChangeConditional = () ->
    if @conditional1.criteria
      @selectedConditional.and = [@conditional1]
    else
      @selectedConditional.and = []
    @refreshVisualization()

  @refreshVisualization = () ->
    if @selectedParams['field_a'] and (@selectedParams.arguments['field_b'] or @selectedParams.arguments.function)
      _params =
        spec: @selectedParams
        conditional: @selectedConditional

      VisualizationDataService.getVisualizationData(_params).then((data) =>
        @visualizationData = data.viz_data
        @tableData = data.table_result
      )

  @onSelectFieldA = () ->
    if @attributeA and @attributeA.label
      @selectedParams['field_a'] = @attributeA.label

      if @attributeA.type not in @ATTRIBUTE_TYPES.NUMERIC
        #TODO: don't hardcode, abstract discrete/continuous as a viz type property
        @availableVisualizationTypes = _.reject(@availableVisualizationTypes, (visualizationType) -> visualizationType in ['line', 'scatter'])

        if @selectedVisualizationType in ['line', 'scatter']
          @selectedVisualizationType = @availableVisualizationTypes[0]

      @refreshOperations()
      @refreshVisualization()
    return

  @onSelectFieldB = () ->
    @selectedParams.arguments['field_b'] = @attributeB.label
    @refreshVisualization()
    return

  @onSelectConditional1Field = () ->
    @conditional1.field = @conditional1Field.label

    if @conditional1Field.type in @ATTRIBUTE_TYPES.NUMERIC
      @conditional1IsNumeric = true
      @availableOperators = @OPERATORS.NUMERIC
    else
      @conditional1IsNumeric = false
      @availableOperators = @OPERATORS.DISCRETE

    if not _.some(@availableOperators, (operation) => operation.value is @conditional1.operation)
      @conditional1.operation = @availableOperators[0].value

    # For some reason, this causes a UI glitch with md-select
    # if @conditional1Field.type in @ATTRIBUTE_TYPES.NUMERIC
    #   @availableOperators = @OPERATORS.NUMERIC
    # else
    #   @availableOperators = @OPERATORS.DISCRETE
    # @conditional1.operation = @availableOperators[0].value
    return

  @getConditional1Values = () ->
    return _.findWhere(@attributes, {'label': @conditional1.field})['values']

  @refreshOperations = () ->
    if @attributeA and (@attributeA.type in @ATTRIBUTE_TYPES.NUMERIC or @attributeA.unique)
      @availableOperations = @OPERATIONS.UNIQUE
    else
      @availableOperations = @OPERATIONS.NON_UNIQUE

    @selectedParams.operation = @availableOperations[0].value
    @attributeB = undefined
    @resetIsGrouping()
    return

  @processAttributes = (attributes) ->
    @attributes = []
    _hasTime = false

    for attribute in attributes

      # most of this should be done server-side
      if attribute['is_time_series_column']
        if !_hasTime
          @attributes.push(@ALL_TIME_ATTRIBUTE)
          @ALL_TIME_ATTRIBUTE.child = []
          _hasTime = true

        @ALL_TIME_ATTRIBUTE.child.push(attribute)

      else
        @attributes.push(attribute)

    return

  @getAttributes = (type = {}) ->
    if @attributes
      attributes = @attributes.slice()
    else
      attributes = []

    for attribute in attributes
      attribute.selected = attribute.label is @selectedAttributeLabel

    return attributes

  @getEntities = ->
    if @entities
      entities = @entities.slice()
    else
      entities = []

    for entity in entities
      if entity.child
        entity.activeLabel = @selectedChildEntities[entity.label]

      if not entity.activeLabel
        entity.activeLabel = entity.label

      entity.selected = entity.activeLabel is @selectedEntityLabel

    return entities

  @getProperties = ->
    return @properties

  @getFlattenedEntities = () ->
    entities = []

    if @entities
      for entity in @entities.slice()
        entities.push(entity)

        if entity.child
          for child in entity.child
            child.parentLabel = entity.label
            entities.push(child)

    return entities

  @getSpecs = () ->
    return @specs

  @getVisualizationTypes = () ->
    _visualizationTypes = @VISUALIZATION_TYPE_DATA.slice()

    for visualizationType in _visualizationTypes
      visualizationType.selected = visualizationType.type is @selectedVisualizationType
      visualizationType.enabled = !visualizationType.disabled && visualizationType.type in @availableVisualizationTypes

    return _visualizationTypes

  @selectVisualizationType = (type) ->
    @selectedVisualizationType = type
    return

  @selectEntity = (entityLabel, parentEntityLabel) ->
    if @selectedEntityLabel is entityLabel
      return @resetDIDParams()

    if parentEntityLabel
      return @selectChildEntity(parentEntityLabel, entityLabel)

    @selectedEntityLabel = entityLabel
    @selectedParams['field_a'] = entityLabel

    @closeMenu()
    @refreshVisualization()
    return

  @selectChildEntity = (entityLabel, childEntityLabel) ->
    @selectedChildEntities[entityLabel] = childEntityLabel
    @selectEntity(childEntityLabel)
    @closeMenu()
    return

  @datasetsLoaded = false
  @propertiesLoaded = false
  @specsLoaded = false

  @resetParams()

  @retrieveProperties = () ->
    PropertiesService.getEntities({ pID: $rootScope.pID, dID: @selectedDataset.dID }).then((entities) =>
      @entitiesLoaded = true
      @entities = entities
      console.log("Loaded entities", @entities)
    )

    PropertiesService.getAttributes({ pID: $rootScope.pID, dID: @selectedDataset.dID }).then((attributes) =>
      @attributesLoaded = true
      @processAttributes(attributes)
      console.log("Loaded attributes", attributes)
    )

    PropertiesService.getProperties({ pID: $rootScope.pID, dID: @selectedDataset.dID }).then((properties) =>
      @propertiesLoaded = true
      @properties = properties
      console.log("Loaded properties", @properties)
    )
    return

  pIDRetrieved.promise.then((r) =>
    DataService.getDatasets().then((datasets) =>
      @datasetsLoaded = true
      @datasets = datasets
      @setDataset(datasets[0])
      console.log("Datasets loaded!", @datasets)
    )

    vizSpecServiceParams = {}
    VizSpecService.getVizSpecs(vizSpecServiceParams).then((specs) =>
      @specsLoaded = true
      @specs = specs
      console.log("Specs loaded!", @specs)
    )
  )

  @
)
