// Generated by CoffeeScript 1.9.1
(function() {
  'use strict';
  var EventEmitter, Worker, childProcess, log,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  childProcess = require('child_process');

  EventEmitter = require('events').EventEmitter;

  log = require('./log');

  Worker = (function(superClass) {
    extend(Worker, superClass);

    function Worker(file) {
      if (!file) {
        throw Error('A worker MUST have a file to run!');
      }
      Worker.__super__.constructor.call(this);
      this.process = childProcess.fork(file);
      this.pid = this.process.pid;
      this.status = Worker.STARTING;
      this.process.once('message', this.onReady.bind(this));
    }

    Worker.prototype.onReady = function(message) {
      if (this.status === Worker.STARTING) {
        log.debug("Worker " + this.pid + " ready.");
        this.status = Worker.READY;
        return this.emit('ready', this);
      }
    };

    Worker.prototype.onMessage = function(callback, message) {
      callback(message);
      this.status = Worker.READY;
      return this.emit('ready', this);
    };

    Worker.prototype.send = function(message, callback) {
      this.status = Worker.BUSY;
      this.emit('busy');
      this.process.once('message', this.onMessage.bind(this, callback));
      return this.process.send(message);
    };

    return Worker;

  })(EventEmitter);

  Worker.STARTING = 'STARTING';

  Worker.READY = 'READY';

  Worker.BUSY = 'BUSY';

  module.exports = Worker;

}).call(this);
