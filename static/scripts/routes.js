// Generated by CoffeeScript 1.6.3
(function() {
  diveApp.config(function($stateProvider, $urlRouterProvider) {
    $urlRouterProvider.otherwise("/");
    return $stateProvider.state('landing', {
      url: '/',
      templateUrl: 'static/views/landing.html',
      resolve: {
        allProjectsService: function(AllProjectsService) {
          return AllProjectsService.promise;
        }
      }
    }).state('engine', {
      url: '/:formattedUserName/:formattedProjectTitle',
      templateUrl: 'static/views/project.html',
      resolve: {
        formattedUserName: function($stateParams) {
          return $stateParams.formattedUserName;
        },
        formattedProjectTitle: function($stateParams) {
          return $stateParams.formattedProjectTitle;
        },
        projectID: function($stateParams, ProjectIDService) {
          return ProjectIDService.promise($stateParams.formattedProjectTitle);
        }
      }
    }).state('engine.data', {
      url: '/data',
      templateUrl: 'static/views/data_view.html',
      controller: 'DatasetListCtrl',
      resolve: {
        initialData: function(DataService) {
          return DataService.promise;
        }
      }
    }).state('engine.ontology', {
      url: '/ontology',
      templateUrl: 'static/views/edit_ontology.html',
      controller: 'OntologyEditorCtrl',
      resolve: {
        initialData: function(DataService) {
          return DataService.promise;
        },
        propertyService: function(PropertyService) {
          return PropertyService.promise;
        }
      }
    }).state('engine.visualize', {
      url: '/visualize',
      templateUrl: 'static/views/create_viz.html',
      controller: 'CreateVizCtrl',
      resolve: {
        initialData: function(DataService) {
          return DataService.promise;
        },
        propertyService: function(PropertyService) {
          return PropertyService.promise;
        },
        specificationService: function(SpecificationService) {
          return SpecificationService.promise;
        },
        vizDataService: function(VizDataService) {
          return VizDataService.promise;
        }
      }
    }).state('engine.assemble', {
      url: '/assemble',
      templateUrl: 'static/views/assemble_engine.html',
      controller: 'AssembleCtrl'
    });
  });

}).call(this);
