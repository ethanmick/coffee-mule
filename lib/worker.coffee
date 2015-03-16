'use strict'
#
# Ethan Mick
# 2015
#
childProcess = require('child_process')
EventEmitter = require('events').EventEmitter
log = require './log'

class Worker extends EventEmitter

  constructor: (file)->
    throw Error('A worker MUST have a file to run!') unless file
    super()
    @process = childProcess.fork(file)
    @pid = @process.pid
    @status = Worker.STARTING
    @process.once 'message', @onReady.bind(this)

  onReady: (message)->
    if @status is Worker.STARTING
      log.debug "Worker #{@pid} ready."
      @status = Worker.READY
      @emit 'ready', this

  onMessage: (callback, message)->
    callback(message)
    @status = Worker.READY
    @emit 'ready', this

  send: (message, callback)->
    @status = Worker.BUSY
    @emit 'busy'
    @process.once 'message', @onMessage.bind(this, callback)
    @process.send(message)

Worker.STARTING = 'STARTING'
Worker.READY    = 'READY'
Worker.BUSY     = 'BUSY'

module.exports = Worker
