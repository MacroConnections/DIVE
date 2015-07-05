$ = require('jquery')

angular.module('diveApp.data').directive 'table', [
  '$window'
  '$timeout'
  ($window, $timeout) ->
    return {
      restrict: 'EA'
      scope:
        data: '='
        onClick: '&'
        selector: '='
        headers: '='

      link: (scope, ele, attrs) ->

        $window.onresize = ->
          scope.$apply()
          return

        scope.$watch (->
          angular.element($window)[0].innerWidth
          return
        ), ->
          scope.render scope.data, scope.selector, scope.headers
          return

        scope.$watchCollection '[data, selector, headers]', ((newData) ->
          scope.render newData[0], newData[1], newData[2]
          return
        ), true

        # Resolving evaluated attribute to actual value
        # http://stackoverflow.com/questions/12371159/how-to-get-evaluated-attributes-inside-a-custom-directive
        attrs.$observe 'selector', (actual_value) ->
          ele.val 'selector=' + actual_value
          scope.selector = actual_value
          return

        scope.render = (data, selector, headers) ->
          console.log 'Rendering table', data, selector, headers

          if !data
            return

          if renderTimeout
            clearTimeout renderTimeout

          renderTimeout = $timeout((->
            pluckedHeaders = _.pluck(headers, 'name')
            console.log pluckedHeaders

            container = $(selector).get(0)
            console.log 'container', container

            hot = new Handsontable(container,
              data: data
              height: 500
              colHeaders: pluckedHeaders
              rowHeaders: true
              stretchH: 'all'
              columnSorting: true
              contextMenu: true)
            return
          ), 200)

        return

    }
]
