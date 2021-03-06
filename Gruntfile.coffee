module.exports = (grunt) ->

  # Utilities
  # =========
  path = require 'path'

  # Package
  # =======
  pkg = require './package.json'

  # Modules
  # =======
  # TODO: Remove this as soon as uRequire releases 0.3 which will able to
  #  do this for us in the right order magically.
  modules = [
    'temp/chaplin/application.js'
    'temp/chaplin/mediator.js'
    'temp/chaplin/dispatcher.js'
    'temp/chaplin/composer.js'
    'temp/chaplin/controllers/controller.js'
    'temp/chaplin/models/collection.js'
    'temp/chaplin/models/model.js'
    'temp/chaplin/views/layout.js'
    'temp/chaplin/views/view.js'
    'temp/chaplin/views/collection_view.js'
    'temp/chaplin/lib/route.js'
    'temp/chaplin/lib/router.js'
    'temp/chaplin/lib/delayer.js'
    'temp/chaplin/lib/event_broker.js'
    'temp/chaplin/lib/support.js'
    'temp/chaplin/lib/composition.js'
    'temp/chaplin/lib/sync_machine.js'
    'temp/chaplin/lib/utils.js'
    'temp/chaplin/lib/helpers.js'
    'temp/chaplin.js'
  ]

  # Configuration
  # =============
  grunt.initConfig

    # Package
    # -------
    pkg: pkg

    # Clean
    # -----
    clean:
      build: 'build'
      temp: 'temp'
      components: 'components'
      test: ['test/temp*', 'test/coverage']

    # Compilation
    # -----------
    coffee:
      compile:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'src'
          src: '**/*.coffee'
          ext: '.js'
        ]

      test:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'test/spec'
          src: '**/*.coffee'
          ext: '.js'
        ]

      options:
        bare: true

    # Module conversion
    # -----------------
    urequire:
      AMD:
        bundlePath: 'temp/'
        outputPath: 'temp/'

        options:
          forceOverwriteSources: true
          relativeType: 'bundle'

    # Module naming
    # -------------
    # TODO: Remove this when uRequire hits 0.3
    copy:
      universal:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

        options:
          processContent: (content, path) ->
            name = ///temp/(.*)\.js///.exec(path)[1]
            # data = content
            data = content.replace /require\('/g, "loader('"
            """
            loader.register('#{name}', function(e, r, module) {
            #{data}
            });
            """

      amd:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

        options:
          processContent: (content, path) ->
            name = ///temp/(.*)\.js///.exec(path)[1]
            content.replace ///define\(///, "define('#{name}',"

      test:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

      beforeInstrument:
        files: [
          expand: true
          dest: 'test/temp-original/'
          cwd: 'test/temp'
          src: '**/*.js'
        ]

      afterInstrument:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'test/temp-original'
          src: '**/*.js'
        ]

    # Module concatenation
    # --------------------
    # TODO: Remove this when uRequire hits 0.3
    concat:
      universal:
        files: [
          dest: 'build/<%= pkg.name %>.js'
          src: modules
        ]

      options:
        separator: ';'

        banner: '''
        /*!
         * Chaplin <%= pkg.version %>
         *
         * Chaplin may be freely distributed under the MIT license.
         * For all details and documentation:
         * http://chaplinjs.org
         */

        (function(){

        var loader = (function() {
          var modules = {};
          var cache = {};

          var dummy = function() {return function() {};};
          var initModule = function(name, definition) {
            var module = {id: name, exports: {}};
            definition(module.exports, dummy(), module);
            var exports = cache[name] = module.exports;
            return exports;
          };

          var loader = function(path) {
            if (cache.hasOwnProperty(path)) return cache[path];
            if (modules.hasOwnProperty(path)) return initModule(path, modules[path]);
            throw new Error('Cannot find module "' + name + '"');
          };

          loader.register = function(bundle, fn) {
            modules[bundle] = fn;
          };
          return loader;
        })();


        '''
        footer: '''

        var regDeps = function(Backbone, _) {
          loader.register('backbone', function(exports, require, module) {
            module.exports = Backbone;
          });
          loader.register('underscore', function(exports, require, module) {
            module.exports = _;
          });
        };

        if (typeof define === 'function' && define.amd) {
          define(['backbone', 'underscore'], function(Backbone, _) {
            regDeps(Backbone, _);
            return loader('chaplin');
          });
        } else if (typeof module === 'object' && module && module.exports) {
          regDeps(require('backbone').Backbone, require('underscore'));
          module.exports = loader('chaplin');
        } else if (typeof require === 'function') {
          regDeps(window.Backbone, window._);
          window.Chaplin = loader('chaplin');
        } else {
          throw new Error('Chaplin requires Common.js or AMD modules');
        }

        })();
        '''

    # Lint
    # ----
    coffeelint:
      source: 'src/**/*.coffee'
      grunt: 'Gruntfile.coffee'

    # Instrumentation
    # ---------------
    instrument:
      files: [
        'test/temp/chaplin.js'
        'test/temp/chaplin/**/*.js'
      ]

      options:
        basePath: '.'

    storeCoverage:
      options:
        dir : '.'
        json : 'coverage.json'
        coverageVar : '__coverage__'

    makeReport:
      src: 'coverage.json'
      options:
        type: 'html'
        dir: 'test/coverage'

    # Browser dependencies
    # --------------------
    bower:
      install:
        options:
          targetDir: './test/components'
          cleanup: true

    # Test runner
    # -----------
    mocha:
      index:
        src: ['test/index.html']
        # options:
        #   grep: 'autoAttach'
        #   mocha:
        #     grep: 'autoAttach'

    # Minify
    # ------
    uglify:
      options:
        mangle: false
      universal:
        files:
          'build/chaplin.min.js': 'build/chaplin.js'

    # Compression
    # -----------
    compress:
      files: [
        src: 'build/chaplin.min.js'
        dest: 'build/chaplin.min.js.gz'
      ]

    # Watching for changes
    # --------------------
    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: [
          'coffee:compile'
          'urequire'
          'copy:amd'
          'copy:test'
          'mocha'
        ]

      test:
        files: ['test/spec/*.coffee'],
        tasks: [
          'coffee:test'
          'mocha'
        ]

  # Events
  # ======
  grunt.event.on 'mocha.coverage', (coverage) ->
    # This is needed so the coverage reporter will find the coverage variable.
    global.__coverage__ = coverage

  # Dependencies
  # ============
  for name of pkg.devDependencies when name.substring(0, 6) is 'grunt-'
    grunt.loadNpmTasks name

  # Tasks
  # =====

  # Prepare
  # -------
  grunt.registerTask 'prepare', [
    'clean'
    'bower'
    'clean:components'
  ]

  # Build
  # -----

  grunt.registerTask 'build', [
    'coffee:compile'
    'copy:universal'
    'concat:universal'
    'uglify'
  ]

  # Lint
  # ----
  grunt.registerTask 'lint', 'coffeelint'

  # Test
  # ----
  grunt.registerTask 'test', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'copy:test'
    'coffee:test'
    'mocha'
  ]

  # Coverage
  # --------
  grunt.registerTask 'cover', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'copy:test'
    'coffee:test'
    'copy:beforeInstrument'
    'instrument'
    'mocha'
    'storeCoverage'
    'copy:afterInstrument'
    'makeReport'
  ]

  # Test Watcher
  # ------------
  grunt.registerTask 'test-watch', [
    'test'
    'watch'
  ]

  # Publish Documentation
  # ---------------------
  grunt.registerTask 'docs:publish', 'Publish docs to gh-pages branch.', ->
    path = require('path')
    temp = require('temp')

    continuation = this.async()
    tmpDirPath = temp.path()

    grunt.file.recurse path.join('docs'), (abspath, rootdir, subdir, filename) ->
      parent = if subdir then path.join(tmpDirPath, subdir) else tmpDirPath
      grunt.file.mkdir parent
      grunt.file.copy abspath, path.join(parent, filename)
    gitArgs = [
      ['init', '.']
      ['add', '.'],
      ['commit', '-m', "Add docs from #{(new Date).toISOString()}"],
      ['remote', 'add', 'origin', 'git@github.com:chaplinjs/chaplin.git'],
      ['push', 'origin', 'master:refs/heads/gh-pages', '--force']
    ]
    gitRunner = (args, next) ->
      grunt.util.spawn {cmd: "git", args: args, opts: {cwd: tmpDirPath}}, (error, result, code) -> next(error)
    grunt.util.async.forEachSeries gitArgs, gitRunner, ->
      grunt.file.delete tmpDirPath, force: true
      grunt.log.writeln "Published docs to gh-pages."
      continuation()

  # Default
  # -------
  grunt.registerTask 'default', [
    'lint'
    'clean'
    'build'
    'test'
  ]
