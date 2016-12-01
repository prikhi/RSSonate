'use strict';

require('./index.html');
require('style!css!font-awesome/css/font-awesome.css');
require('./styles.sass');


var Elm = require('./Main.elm');
var node = document.getElementById('main');

var token = localStorage.getItem('authToken');
var app = Elm.Main.embed(node, {"authToken": token});


/* Resize the Content Panel to Take Up the Remaining Window Height */
var resizeContentPanel = function() {
  var totalHeight = window.innerHeight;
  var content = document.getElementById('content-block');
  var contentHeight = totalHeight - content.offsetTop -
    content.offsetParent.offsetParent.offsetTop - 55;
  content.style.height = contentHeight + "px";
};

window.onresize = resizeContentPanel;

app.ports.triggerResize.subscribe(function() {
  setTimeout(resizeContentPanel, 50);
});

app.ports.storeAuthToken.subscribe(function(token) {
  localStorage.setItem('authToken', token);
});

app.ports.removeAuthToken.subscribe(function() {
  localStorage.removeItem('authToken');
});
