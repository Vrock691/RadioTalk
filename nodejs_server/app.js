const express = require('express');
const { createServer } = require('node:http');
const { join } = require('node:path');
const { Server } = require('socket.io');

const app = express();
const cors = require('cors')
const server = createServer(app);
const io = new Server(server);

app.use(cors())
app.get('/', (req, res) => {
  res.json({working: true});
})

io.on('connection', (socket) => {
  console.log('a user connected');
  
  socket.on('disconnect', () => {
    console.log('user disconnected');
  });

  socket.on('audioCast', (data) => {
    console.log(data);
    socket.broadcast.emit('audioCast', data)
  })
});

server.listen(3008, () => {
  console.log('server running at http://localhost:3008');
});