'use strict'

should = require('chai').should()
WorkQueue = require '../../lib/work_queue'

describe 'WorkQueue Integration', ->

  it 'should create multiple workers', (done)->
    q = new WorkQueue('./test/fixtures/worker1.coffee', numWorkers: 2)
    setTimeout ->
      q.workers.should.have.length 2
      done()
    , 100

  it 'should run jobs', (done)->
    q = new WorkQueue('./test/fixtures/worker1.coffee', numWorkers: 2)
    q.enqueue 10, (result)->
      result.should.equal 89
      done()

  it 'should default to cpu workers', ->
    q = new WorkQueue('./test/fixtures/worker1.coffee')
    num = require('os').cpus().length
    q.workers.length.should.equal num

  it 'should restart if a worker crashes', (done)->
    q = new WorkQueue('./test/fixtures/worker2.coffee', numWorkers: 1)
    w = q.workers[0]
    w.process.on 'exit', ->
      setTimeout ->
        q.workers.should.have.length 1
        done()
      , 200
    q.workers.should.have.length 1
    q.enqueue(10)

  it 'should timeout if given a timeout', (done)->
    q = new WorkQueue('./test/fixtures/worker3.coffee', numWorkers: 1)
    q.enqueue 'data', 1000, (data)->
      data.should.be.empty
      done()
