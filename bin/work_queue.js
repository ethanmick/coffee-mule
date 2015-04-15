// Generated by CoffeeScript 1.9.1
(function() {
  'use strict';
  var WorkQueue, Worker, log, os;

  os = require('os');

  Worker = require('./worker');

  log = require('./log');

  WorkQueue = (function() {
    function WorkQueue(script, options) {
      var base, base1, cpus, i;
      this.script = script;
      this.options = options != null ? options : {};
      this.workers = [];
      this.queue = [];
      cpus = os.cpus().length;
      if ((base = this.options).numWorkers == null) {
        base.numWorkers = cpus;
      }
      if ((base1 = this.options).maxWorkers == null) {
        base1.maxWorkers = cpus * 2;
      }
      i = 0;
      log.debug("Starting " + this.options.numWorkers + " workers..");
      while (i++ < this.options.numWorkers) {
        this.fork();
      }
    }

    WorkQueue.prototype.fork = function() {
      var worker;
      worker = new Worker(this.script);
      worker.on('ready', this._run.bind(this));
      worker.process.on('exit', (function(_this) {
        return function(code, signal) {
          var i, j, len, ref, w;
          if (code !== 0) {
            log.warn("Worker process " + worker.pid + " died. Respawning...");
            ref = _this.workers;
            for (i = j = 0, len = ref.length; j < len; i = ++j) {
              w = ref[i];
              if (w === void 0 || w.pid === worker.pid) {
                _this.workers.splice(i, 1);
              }
            }
            return _this.fork();
          }
        };
      })(this));
      return this.workers.push(worker);
    };

    WorkQueue.prototype.enqueue = function(task, timeout, callback) {
      if (!callback) {
        callback = timeout;
        timeout = null;
      }
      this.queue.push({
        task: task,
        callback: callback,
        timeout: timeout
      });
      return process.nextTick(this._run.bind(this));
    };

    WorkQueue.prototype._run = function(worker) {
      var callback, j, len, queued, ref, timeoutId, w;
      log.debug('RUNNING', this.queue);
      if (this.queue.length === 0) {
        return;
      }
      if (!worker) {
        ref = this.workers;
        for (j = 0, len = ref.length; j < len; j++) {
          w = ref[j];
          if (w.status === Worker.READY) {
            worker = w;
            break;
          }
        }
      }
      if (!worker && this.options.autoexpand && this.workers.length < this.options.maxWorkers) {
        return this.fork();
      }
      if (!worker) {
        return;
      }
      queued = this.queue.shift();
      callback = null;
      if (queued.timeout) {
        log.debug('timeout', queued.timeout);
        timeoutId = null;
        callback = function() {
          clearTimeout(timeoutId);
          return queued.callback.apply(this, arguments);
        };
        timeoutId = setTimeout((function(_this) {
          return function() {
            worker.process.kill('SIGINT');
            return callback.call(_this, _this.options.timeoutResult || {});
          };
        })(this), queued.timeout);
      } else {
        callback = queued.callback;
      }
      return worker.send(queued.task, callback);
    };

    return WorkQueue;

  })();

  module.exports = WorkQueue;

}).call(this);
