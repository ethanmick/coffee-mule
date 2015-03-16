'use strict'
#
# Ethan Mick
# 2015
#
os = require 'os'
Worker = require './worker'
log = require './log'

class WorkQueue

  constructor: (script, numWorkers = os.cpus().length)->
    @workers = []
    @queue = []
    i = 0

    log.debug "Starting #{numWorkers} workers.."

    @fork(script) while i++ < numWorkers

  fork: (script)->
    worker = new Worker(script)
    worker.on 'ready', @_run.bind(this)
    worker.process.on 'exit', (code, signal)=>
      if code isnt 0 # Code will be non-zero if process dies suddenly
        log.warn "Worker process #{worker.pid} died. Respawning..."
        for w, i in @workers
          if w.pid is worker.pid
            @workers.splice(i, 1) # Remove dead worker from pool.
        @fork(script) # FTW!

    @workers.push(worker)

  enqueue: (task, callback)->
    @queue.push task: task, callback: callback
    process.nextTick(@_run.bind(this))

  _run: (worker)->
    return if @queue.length is 0

    unless worker
      # Find the first available worker.
      for w in @workers
        if w.status is Worker.READY
          worker = w
          break
    return unless worker

    queued = @queue.shift()
    worker.send(queued.task, queued.callback)

module.exports = WorkQueue
