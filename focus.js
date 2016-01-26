'use strict';

const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;
var mainWindow = null;

app.on('window-all-closed', function() {
  app.quit();
});

app.on('ready', function() {
  var atomScreen = require('screen');
  var displays = atomScreen.getAllDisplays();
  var externalDisplay = null;
  for (var i in displays) {
    if (displays[i].bounds.x > 0 || displays[i].bounds.y > 0) {
      externalDisplay = displays[i];
      break;
    }
  }

    mainWindow = new BrowserWindow({
      width                  : 3840,
      height                 : 2160,
      transparent            : true,
      frame                  : false,
      moveable               : false,
      resizable              : false,
      enableLargerThanScreen : true,
      x: -8,
      y: -8
    });
    mainWindow.loadURL('file://' + __dirname + '/index.html');
    mainWindow.on('closed', function() {
      mainWindow = null;
    });
});
