'use strict'

should = require('chai').should()
WorkQueue = require '../../lib/work_queue'

describe 'WorkQueue', ->

  it 'should exist', ->
    should.exist WorkQueue

  it 'should create 0 workers if told', ->
    q = new WorkQueue(null, 0)
    q.workers.should.be.empty
    q.queue.should.be.empty

  it 'should enqueue a task', ->
    q = new WorkQueue(null, 0)
    q.enqueue('someting')
    q.queue.should.have.length 1

  it 'should _run a worker', (done)->
    q = new WorkQueue(null, 0)
    q.queue.push 'hi'
    worker = send: -> done()
    q._run(worker)
