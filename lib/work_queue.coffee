'use strict'
#
# Ethan Mick
# 2015
#
os = require 'os'
Worker = require './worker'
log = require './log'

class WorkQueue

  constructor: (@script, @options = {})->
    @workers = []
    @queue = []
    cpus = os.cpus().length
    @options.numWorkers ?= cpus
    @options.maxWorkers ?= cpus * 2

    i = 0
    log.debug "Starting #{@options.numWorkers} workers.."
    @fork() while i++ < @options.numWorkers

  fork: ->
    worker = new Worker(@script)
    worker.on 'ready', @_run.bind(this)
    worker.process.on 'exit', (code, signal)=>
      if code isnt 0 # Code will be non-zero if process dies suddenly
        log.warn "Worker process #{worker.pid} died. Respawning..."
        for w, i in @workers
          if w.pid is worker.pid
            @workers.splice(i, 1) # Remove dead worker from pool.
        @fork() # FTW!

    @workers.push(worker)

  enqueue: (task, timeout, callback)->
    if not callback
      callback = timeout
      timeout = null

    @queue.push(task: task, callback: callback, timeout: timeout)
    process.nextTick(@_run.bind(this))

  _run: (worker)->
    log.debug 'RUNNING', @queue
    return if @queue.length is 0

    unless worker
      # Find the first available worker.
      for w in @workers
        if w.status is Worker.READY
          worker = w
          break

    return @fork() if not worker and @options.autoexpand and @workers.length < @options.maxWorkers
    return unless worker

    queued = @queue.shift()
    callback = null

    if queued.timeout
      log.debug 'timeout', queued.timeout
      timeoutId = null

      callback = ->
        clearTimeout(timeoutId)
        queued.callback.apply(this, arguments)

      timeoutId = setTimeout =>
        worker.process.kill('SIGINT')
        callback.call(this, @options.timeoutResult or {})
      , queued.timeout
    else
      callback = queued.callback

    worker.send(queued.task, callback)

module.exports = WorkQueue
