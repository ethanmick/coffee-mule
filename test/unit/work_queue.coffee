'use strict'

should = require('chai').should()
sinon = require 'sinon'
WorkQueue = require '../../lib/work_queue'

describe 'WorkQueue', ->

  it 'should exist', ->
    should.exist WorkQueue

  it 'should create 0 workers if told', ->
    q = new WorkQueue(null, numWorkers: 0)
    q.workers.should.be.empty
    q.queue.should.be.empty

  it 'should enqueue a task', ->
    q = new WorkQueue(null, numWorkers: 0)
    q.enqueue('someting')
    q.queue.should.have.length 1

  it 'should _run a worker', (done)->
    q = new WorkQueue(null, numWorkers: 0)
    q.queue.push 'hi'
    worker = send: -> done()
    q._run(worker)

  it 'should call `fork` if autoexpand is on', ->
    q = new WorkQueue(null, numWorkers: 0, autoexpand: yes)
    q.queue.push 'hi'
    stub = sinon.stub(q, 'fork')
    q._run()
    stub.calledOnce.should.be.true
    stub.restore()
