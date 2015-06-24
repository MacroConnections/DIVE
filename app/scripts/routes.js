require('angular');
require('angular-ui-router');

angular.module('diveApp.routes', ['ui.router'])

angular.module('diveApp.routes').config(function($stateProvider, $urlRouterProvider, $locationProvider) {  
  $stateProvider
  .state('landing', {
    url: '^/',
    templateUrl: 'modules/landing/landing.html',
    controller: function($scope, $rootScope, $state, AuthService, user, loggedIn) {
      $rootScope.user = user;
      $rootScope.loggedIn = loggedIn;

      if (loggedIn)
        $state.go('landing.create');
      else
        $state.go('landing.noauth');
    },
    resolve: {
      user: function(AuthService) {
        return AuthService.getCurrentUser();          
      },
      loggedIn: function(AuthService) {
        return AuthService.isAuthenticated();
      }
    }
  })
    .state('landing.create', {
      url: 'create',
      authenticate: true,
      templateUrl: 'modules/landing/create.html',
      controller: 'CreateProjectCtrl'
    })
    .state('landing.noauth', {
      url: 'new',
      authenticate: false,
      controller: function($scope, $rootScope, $state, AuthService, project) {
        $state.go('project.data.upload', {
          formattedProjectTitle: project.data.formatted_title
        });

      },
      resolve: {
        project: function(ProjectService) {
          return ProjectService.createProject({anonymous: true});
        }        
      }
    })
    .state('landing.projects', {
      url: 'projects',
      authenticate: true,
      templateUrl: 'modules/landing/projects.html',
      controller: 'ProjectListCtrl',
      resolve: {
        projects: function(ProjectService, AuthService) {
          var projects = ProjectService.getProjects({ userName: AuthService.getCurrentUser().userName });
          console.log("Projects", projects);
          return projects;
        }
      }
    })
    .state('landing.reports', {
      url: 'reports',
      authenticate: true,
      templateUrl: 'modules/landing/reports.html'
    })
    .state('landing.about', {
      url: 'about',
      authenticate: true,
      templateUrl: 'modules/landing/about.html'
    })
    .state('landing.login', {
      url: 'login',
      authenticate: false,
      controller: 'AuthenticateCtrl',
      templateUrl: 'modules/landing/login.html'
    })
    .state('landing.signup', {
      url: 'signup',
      authenticate: false,
      controller: 'AuthenticateCtrl',
      templateUrl: 'modules/landing/signup.html'
    })
  .state('logout', {
    url: '/logout',
    controller: function($scope, $rootScope, $state, $stateParams, AuthService) {
      AuthService.logoutUser(function() {
        $rootScope.user = null;
        $rootScope.loggedIn = false;
        $state.go('landing.login');          
      });      
    }
  })
  .state('project', {
    url: '/:formattedProjectTitle',
    templateUrl: 'modules/project/project.html',
    controller: function($scope, $rootScope, $state, $stateParams, AuthService, user, loggedIn) {
      $scope.projectTitle = $stateParams.formattedProjectTitle.split('-').join(' ');
      $rootScope.user = user;
      $rootScope.loggedIn = loggedIn;
    },
    resolve: {
      user: function(AuthService) {
        return AuthService.getCurrentUser();          
      },
      loggedIn: function(AuthService) {
        return AuthService.isAuthenticated();
      },
      formattedProjectTitle: function($stateParams) {
        return $stateParams.formattedProjectTitle;
      },
      pID: function($stateParams, $rootScope, AuthService, ProjectIDService) {
        var params = {
          formattedProjectTitle: $stateParams.formattedProjectTitle, 
          userName: AuthService.getCurrentUser().userName
        }
        return ProjectIDService.getProjectID(params);
      }
    }
  })
  .state('project.overview', {
    url: '/overview',
    templateUrl: 'modules/project/project_overview.html',
    controller: 'OverviewCtrl'
  })
  .state('project.data', {
    abstract: true,
    authenticate: true,
    url: '/data',
    templateUrl: 'modules/data/data.html',
    controller: 'DataCtrl'
  })
    .state('project.data.upload', {
      url: '/upload',
      templateUrl: 'modules/data/upload_datasets.html',
      controller: 'UploadCtrl'
    })
    .state('project.data.preloaded', {
      url: '/preloaded',
      templateUrl: 'modules/data/preloaded_datasets.html',
      controller: 'PreloadedDataCtrl',
    })
    .state('project.data.inspect', {
      url: '/inspect/:dID',
      templateUrl: 'modules/data/inspect_dataset.html',
      controller: 'InspectDataCtrl'
    })

  .state('project.visualize', {
    url: '/visualize',
    authenticate: true,
    templateUrl: 'modules/visualization/visualization.html',
    controller: 'VisualizationCtrl'
  })
  .state('project.export', {
    url: '/export',
    authenticate: true,
    templateUrl: 'modules/export/export.html',
    controller: 'ExportCtrl'
  })
  .state('project.ontology', {
    url: '/ontology',
    templateUrl: 'modules/property/property.html',
    controller: 'OntologyEditorCtrl',
  });

  // .state('embed', {
  //   url: '/embed/:pID/:sID',
  //   templateUrl: 'modules/embed/embed.html',
  //   controller: 'EmbedCtrl',
  //   resolve: {
  //     vizDataService: function(VizDataService) {
  //       return VizDataService.promise;
  //     },
  //     exportedVizSpecService: function(ExportedVizSpecService) {
  //       return ExportedVizSpecService.promise;
  //     }
  //   }
  // })

  $urlRouterProvider.otherwise("/");
  $locationProvider.html5Mode(true);
});
