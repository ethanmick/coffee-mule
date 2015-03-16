'use strict'

childProcess = require 'child_process'
should = require('chai').should()
sinon = require 'sinon'
Worker = require '../../lib/worker'


describe 'Worker', ->

  it 'should send and receive messages', (done)->
    w = new Worker('./test/fixtures/worker1.coffee')
    w.once 'ready', ->
      w.send 10, (result)->
        result.should.equal 89
        done()
