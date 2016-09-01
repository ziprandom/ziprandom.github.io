+++
author = "Zip Random"
tags = ["emacs", "angular.js"]
title = "Org-Mode Powered AngularJS Boilerplate"
date = "2013-11-04T16:00:00-03:00"
+++

This is my custom angular.js boilerplate Setup based on Emacs's Org Mode
and it´s impressive tangle functionality. You can load this page´s org
source code in Emacs and start playing around with angular.

<!--more-->

After opening the File in an emacs Buffer the elisp source block in the
post-processing section has to be evaluated ( C-x C-e after the last
parenthesis ) for coffee to be set up correctly.

### 1 Requirements


-   the coffee script compiler (coffee command line tool to translate
    coffe-script into java-script)
-   Emacs 24
-   org-mode (via M-x install-package inside Emacs)
-   coffee-mode (via M-x install-package)

### 2 Creating the Dummy


in this org-files buffer run the command: M-x org-bable-tangleis creates
a www directory inside the org-files location with these files:

-   index.html
-   project.coffee
-   project.js
-   css/style.css

and tries to open the index.html in your browser. Now you can try out [a
very basic angular.js example](/stuff/www/index.html).

### 3 Editing the code

You can navigate inside any of the code-blocks below and alter it´s
contents. As soon as your finished run M-x org-bable-tangle again to
export the source-code files. You can edit each code block in a separate
buffer with the languages major mode activated by pressing C-c ' with
your cursor placed inside the code-block.

### 4 Source Code

#### 4.1 Post-Processing (coffee -\> js)

This must be evaluated before the first tangle export in order to setup
automatic coffe-script compilation.

``` {.commonlisp}
  (add-hook 'org-babel-post-tangle-hook
            (
             lambda ()
                    (setq coffee-command "/usr/bin/coffee")
                    (coffee-compile-file)

                    (browse-url (concat
                                 "file:" (file-name-directory buffer-file-name)
                                 "index.html"))
                    )
            )
```

#### 4.2 Html Template

The index.html associates the \<html\> tag with the overall app (angular
module) and the \<body\> tag with the MainCtrl. This makes the \$scope
variables (which includes functions) available inside the \<body\> tag.
The **ng-bind** attribute binds the contents of the tag to a variable or
expression ( {{object.age + 1}} ). Note the very usefull ng-repeat
directive. **ng-click** evaluates the associated expression upon
clicking. {{ ... }} Expressions are also used to directly map variables
to attributes (id for example). Input fields can be bound to variables
via the **ng-model** directive.

``` {.commonlisp}
  <!doctype html>
  <html ng-app="app">
    <head>
      <link rel="stylesheet" href="css/style.css">
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.0/jquery.min.js"></script>
      <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.0.8/angular.min.js"></script>
      <script src="http://code.angularjs.org/1.0.8/angular-sanitize.min.js"></script>
      <script src="project.js"></script>
    </head>
    <body ng-controller="MainCtrl">
      <div id="table">
        Click on the table headings for sorting.
        <table class="table-body">
          <tr>
            <th><a href="#" ng-class="{bold: sortVar == 'name'}" ng-click="sortVar = 'name'">Name</a></th>
            <th><a href="#" ng-class="{bold: sortVar == 'age'}" ng-click="sortVar = 'age'">Age</a></th>
            <th><a href="#" ng-class="{bold: sortVar == 'email'}" ng-click="sortVar = 'email'">Email</a></th>
          </tr>
          <tr ng-repeat="object in objects | orderBy:sortVar | filter:query" ng-class="object.name" id="{{object.email}}">
            <td ng-bind="object.name"></td>
            <td><span ng-bind="object.age"></span> <a ng-click="object.age = object.age + 1" href="#">+</a>  <a ng-click="object.age = object.age - 1" href="#">-</a></td>

            <td ng-bind="object.email"></td>
          </tr>
      </div>
      <br/>
      <div id="controlls">
        Filter Table:
        <input type="text" ng-model="query" />
      </div>
    </body>
  </html>
```

#### 4.3 Coffee Script Code

We define an angular.module an load the ngSanitize module ([more on
angular.js modules](http://docs.angularjs.org/api/angular.module)) which
could enable us to use the bindHtml directive to *securely* bind html
contents to elements (not used in this example).

Note also the definition of the MainCtrl Controller. Variables, that we
want to be bound into the view have to be children of the \$scope
object. We may update these bindings via \$scope.apply () -\>
\$scope.myCustomVar = "smth". This is not allways necessary, don´t
remember when exactly it is. Here we also define an array of objects to
iterate over it via the ng-repeat directive in the view.

``` {.coffee}
  # (setq coffee-command "coffee -j project.js")
  angular.module('app', ['ngSanitize'])
  ## Controllers
  @MainCtrl = ($scope, $http) ->
          $scope.sortVar = 'name'
          $scope.objects = [
                                  name: "otto"
                                  age: 23
                                  email: "der.otto@nowhe.re",

                                     name: "fred"
                                     age: 19
                                     email: "man-fred@nowhe.re",

                                  name: "liza"
                                  age: 27
                                  email: "liza@nowhe.re",

                                     name: "clara"
                                     age: 26
                                     email: "oclara@nowhe.re",

                                  name: "mike"
                                  age: 23
                                  email: "mike@nowhe.re"]
          $scope.query = ""
          $scope.clear = () ->
                    $scope.$apply () ->
                            $scope.query = ""
```

#### 4.4 Style.css

``` {.css}
  .bold {
      font-weight: bold;
  }
  a {
      text-decoration: none;
  }
  #table {
      float: left;
  }
  #controlls {
      float: left;
  }
```
