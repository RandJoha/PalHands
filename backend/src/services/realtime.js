let ioInstance = null;

function init(io) {
  ioInstance = io;
}

function io() {
  return ioInstance;
}

function emit(event, payload) {
  if (ioInstance) ioInstance.emit(event, payload);
}

module.exports = { init, io, emit };
