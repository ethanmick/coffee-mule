'use strict'
#
# Ethan Mick
# Demonstate a long running task
#
process.on 'message', (message)->
  setTimeout ->
    process.send('done')
  , 5000

process.send('READY')
