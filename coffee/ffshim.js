// Shim srcObject, from adapter.js
if (window.HTMLMediaElement &&
  !('srcObject' in window.HTMLMediaElement.prototype)) {
  // Shim the srcObject property, once, when HTMLMediaElement is found.
  Object.defineProperty(window.HTMLMediaElement.prototype, 'srcObject', {
    get: function() {
      return this.mozSrcObject;
    },
    set: function(stream) {
      this.mozSrcObject = stream;
    }
  });
}

