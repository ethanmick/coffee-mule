'use strict'

childProcess = require 'child_process'
should = require('chai').should()
sinon = require 'sinon'
Worker = require '../../lib/worker'


describe 'Worker', ->

  it 'should exist', ->
    should.exist Worker

  it 'should have defaults', ->
    stub = sinon.stub(childProcess, 'fork').returns pid: 10, once: ->
    w = new Worker('./test/fixtures/worker1.coffee')
    should.exist w.process
    w.pid.should.equal 10
    w.status.should.equal 'STARTING'
    stub.restore()

  it 'should throw without a script', ->
    ( -> new Worker() ).should.throw

  describe 'A worker instance', ->
    w = null
    beforeEach ->
      stub = sinon.stub(childProcess, 'fork').returns pid: 10, once: ->
      w = new Worker('./test/fixtures/worker1.coffee')
      should.exist w.process
      w.pid.should.equal 10
      w.status.should.equal 'STARTING'
      stub.restore()

    it 'should not get ready if the worker is not starting', ->
      w.status = 'bb'
      w.onReady()
      w.status.should.not.equal 'STARTING'
      w.status.should.not.equal 'READY'

    it 'should get ready', ->
      w.onReady()
      w.status.should.equal 'READY'

    it 'should callback on a message', (done)->
      w.onMessage (test)->
        test.should.equal 'ok'
        done()
      , 'ok'
