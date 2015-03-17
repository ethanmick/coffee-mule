# Coffee Mule

[![Build Status](https://travis-ci.org/ethanmick/coffee-mule.svg?branch=master)](https://travis-ci.org/ethanmick/coffee-mule)

A dash of Coffee with your work queue. While this has been written in CoffeeScript, the `main` file is compiled Javascript, and you can use this in any Node project you want.

## Why this Fork?

Updated Mule to the modern era, and also added a few options that I needed.
* Timeout for tasks
* Automatic pool size increase
* Tests
* Node 0.10, 0.12, and io.js compatibility assurance.

## About

Mule is a work queue for CPU intensive tasks. You can use it to offload tasks that would otherwise kill your fast, responsive event loop.

Mule works by using Node's [child_process.fork()](http://nodejs.org/api/child_process.html#child_process_child_process_fork_modulepath_args_options) method to pre-fork a bunch of processes using a script you define. It sets up a task queue to which you can push blocking tasks onto and listen for the result. As worker processes become available they alert the work queue that they're ready to accept more work. Tasks are sent and results received using node's inbuilt IPC for forked node processes.

Since this creates a separate process it is suitable for containment with the `vm` module.

This is currently being used at:
* [CloudMine](https://cloudmine.me/)
* [Hubify](http://hubify.com)

If you have any issues, please submit a bug.

## Installation

```
npm install coffee-mule --save
```

Then to get up and running:

```coffee
WorkQueue = require('mule').WorkQueue

workQueue = new WorkQueue(__dirname + '/worker.coffee');
workQueue.enqueue 'some data for worker to process', (result)->
  # do something with result
```

## WorkQueue
* script - String, required. The path to the file you wish to have execute the messages. If a CoffeeScript file, it must end in `.coffee`
* options (can be null)
  * numWorkers - Number, the number of workers you want working on the queue. Defaults to the number of CPUs on the computer.
  * maxWorkers - Number, the maximum number of workers you want to expand to, if `autoexpand` is set to true.
  * autoexpand - Bool, should the pool autoexpand. Autoexpand means if a the queue tries to run a job, and no workers are currently available, *and* the max workers has not been reached, it will create a new worker.
  * timeoutResult - Anything (defaults to `{}`), if a job times out, then this is the result which is returned.

An optional timeout can be set when you enqueue an object.

```coffee
workQueue.enqueue 'data', 5000, (result)->
  # result, or timeout result after 5 seconds.
```

## Contrived Example


Imagine you have a node process which needs to stay responsive to web requests, user input or whatever. However it has some heavy CPU intensive work to do calculating fibonacci numbers. Here's how mule can help unburden your poor server:

### parent.js
```javascript
var WorkQueue = require('mule').WorkQueue;

var workQueue = new WorkQueue(__dirname + '/worker.js');

// Generate a series of fibonacci numbers using the work queue to avoid blocking.
var waiting = 100;
for (var i = 1; i <= 100; i++) {
  // Generate random number to calculate a fibonacci sequence on
  var n = Math.floor(Math.random() * 40) + 1;

  // Wrap in anonymous function so we still have access to i & n
  (function (i, n) {
    workQueue.enqueue(n, function (result) {
	  console.log(i + ': fibo(' + n + ') = ' + result);

      if (--waiting === 0) {
	    // All jobs are complete so we can safely exit
		console.log('\nDone.')
		process.exit(0);
	  }
    });
  })(i, n);	
}

console.log('See, no blocking!');
```

### worker.js
```javascript
/**
 * Calculate a Fibonacci number. Note that if you ran this in the main event 
 * loop it would block. 
 */ 
function fibo (n) {
  return n > 1 ? fibo(n - 1) + fibo(n - 2) : 1;
}

// This is where we accept tasks given to us from the parent process.
process.on('message', function (message) {
  // Do some CPU intensive calculations with the number passed.
  var result = fibo(message);

  // Send the result back to the parent process when done.
  process.send(result);
});

/* Send ready signal so parent knows we're ready to accept tasks. This should
 * always be the last line of your worker process script. */
process.send('READY');
```

The worker script is nothing special and can really be anything imaginable. Best of all it's okay to write blocking code in the workers. It's what they're there for.

There are some important things to note however:

1. Always include final line in the example worker above. Without it the parent process won't know that the worker has started successfully. Also ensure that it's the very last thing to execute upon initialization so that you can confidently send tasks to it knowing that everything is ready and in place. If you have async initialization code you should ensure that 'READY' is called after all async init code has completed.
2. `process.on('message'...)` must be present in order to receive jobs from the parent.
3. `process.send(result)` must also be present as the final step of your processing to send back the result and notify the parent process that the worker is ready for more work. If this isn't present or never gets called due to an exception etc., your worker won't be available to receive any more work and will effectively hang.



