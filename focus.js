'use strict';

const bg_loc = '/tmp/tmp_bg.png';
const cp     = require('child_process');
const screen = cp.spawnSync('screencapture', ['-x', bg_loc]);

const electron      = require('electron');
const app           = electron.app;
const BrowserWindow = electron.BrowserWindow;
var   mainWindow    = null;

app.on('window-all-closed', function() {
  app.quit();
});

app.on('ready', function() {
  mainWindow = new BrowserWindow({
    width                  : 3840,
    height                 : 2160,
    transparent            : true,
    frame                  : false,
    moveable               : false,
    resizable              : false,
    enableLargerThanScreen : true,
    x                      : -8,
    y                      : -8
  });

  mainWindow.loadURL('file://' + __dirname + '/index.html');
  mainWindow.on('closed', function() {
    require('fs').unlink(bg_loc);
    mainWindow = null;
  });
});
