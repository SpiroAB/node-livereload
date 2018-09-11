runner = ->
  fs         = require('fs');
  pjson      = require('../package.json')
  version    = pjson.version
  livereload = require './livereload'
  resolve    = require('path').resolve
  opts       = require 'opts'
  debug      = false;

  opts.parse [
    {
      short: "v"
      long:  "version"
      description: "Show the version"
      required: false
      callback: ->
        console.log version
        process.exit(1)
    }
    {
      short: "p"
      long:  "port"
      description: "Specify the port"
      value: true
      required: false
    }
    {
      short: "x"
      long: "exclusions"
      description: "Exclude files by specifying an array of regular expressions. Will be appended to default value which is [/\.git\//, /\.svn\//, /\.hg\//]",
      required: false,
      value: true
    }
    {
      short: "d"
      long: "debug"
      description: "Additional debugging information",
      required: false,
      callback: -> debug = true
    }
    {
      short: "e"
      long: "exts",
      description: "A comma-separated list of extensions you wish to watch. Replaces default extentions",
      required: false,
      value: true
    }
    {
      short: "ee"
      long: "extraExts",
      description: "A comma-separated list of extensions you wish to watch in addition to the defaults (html, css, js, png, gif, jpg, php, php5, py, rb, erb, coffee). If used with --exts, this overrides --exts.",
      required: false,
      value: true
    }
    {
      short: "h"
      long: "https",
      description: "Use https instead of http.",
      required: false,
      value: true
    }
    {
      short: "k"
      long: "key",
      description: "Path to certificate key file.",
      required: false,
      value: true
    }
    {
      short: "c"
      long: "cert",
      description: "Path to certificate file.",
      required: false,
      value: true
    }
    {
      short: "u"
      long: "usepolling"
      description: "Poll for file system changes. Set this to true to successfully watch files over a network.",
      required: false,
      value: true
    }
    {
      short: "w"
      long: "wait"
      description: "delay message of file system changes to browser by `delay` milliseconds"
      required: false
      value: true
    }
  ].reverse(), true

  port = opts.get('port') || 35729
  exclusions = if opts.get('exclusions') then opts.get('exclusions' ).split(',' ).map((s) -> new RegExp(s)) else []
  exts = if opts.get('exts') then opts.get('exts').split(',').map((ext) -> ext.trim()) else  []
  extraExts = if opts.get('extraExts') then opts.get('extraExts').split(',').map((ext) -> ext.trim()) else  []
  usePolling = opts.get('usepolling') || false
  wait = opts.get('wait') || 0;

  options = {
    port: port
    debug: debug
    exclusions: exclusions
    exts: exts
    extraExts: extraExts
    usePolling: usePolling
    delay: wait
  };
  if opts.get('https')
    options = {https: options}
    options.https.key = fs.readFileSync(if opts.get('key') then opts.get('key') else '/cert/local.key')
    options.https.cert = fs.readFileSync(if opts.get('cert') then opts.get('cert') else '/cert/local.crt')
    options.https.requestCert = false;
    options.https.rejectUnauthorized = false;

  server = livereload.createServer(options)

  path = (process.argv[2] || '.')
    .split(/\s*,\s*/)
    .map((x)->resolve(x))
  console.log "Starting LiveReload v#{version} for #{path} on port #{port}."

  server.on 'error', (err) ->
    if err.code == "EADDRINUSE"
      console.log("The port LiveReload wants to use is used by something else.")
    else
      throw err
    process.exit(1)

  server.watch(path)

module.exports =
  run: runner
