'use strict'
###
* Calculate a Fibonacci number. Note that if you ran this in the main event
* loop it would block.
###
fibo = (n)->
  throw Error('THIS IS AN ERROR')

# This is where we accept tasks given to us from the parent process.
process.on 'message', (message)->
  # Do some CPU intensive calculations with the number passed.
  result = fibo(message)

  # Send the result back to the parent process when done.
  process.send(result)

# Send ready signal so parent knows we're ready to accept tasks. This should
# always be the last line of your worker process script. */
process.send('READY')
