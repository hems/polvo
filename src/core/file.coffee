fs = require 'fs'
path = require 'path'

dirs = require '../utils/dirs'
plugins = require '../utils/plugins'
scan = require '../scanner/scan'
MicroEvent = require '../event/microevent'

prefix = "require.register('~path', function(require, exports, module){"
sufix = "});"


module.exports = class File extends MicroEvent

  raw: null
  filepath: null
  relativepath: null

  id: null
  type: null
  deps: null

  uncompiled: null
  compiled: null
  map: null

  compiled: null
  src_map: null

  compiler: null

  constructor:(@filepath)->
    @relativepath = dirs.relative @filepath
    @compiler = @get_compiler()
    @type = @compiler.type

  init:->
    @refresh()

  refresh:->
    @raw = fs.readFileSync @filepath, "utf-8"
    @compile =>
      @deps = @scan_deps()

  compile:( done )->

    @compiler.compile @filepath, @raw, ( @compiled, @map, @uncompiled )=>

      if @type is 'css'
        @wrapped = @compiled
      if @type is 'js'
        @wrapped = prefix.replace '~path', @relativepath
        @wrapped += "\n"
        # @wrapped += @compiled
        @wrapped += "\n"
        @wrapped += sufix

      done?(@)

  scan_deps:->
    deps = scan @filepath, @compiled, true
    @emit 'deps', deps
    deps

    # relative = []
    # for relative in absolute
    #   deps.push path.relative @filepath, dep
    # deps

  get_compiler:->
    for plugin in plugins
      if plugin.ext.test @filepath
        return plugin 