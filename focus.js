'use strict';

const bg_loc  = '/tmp/tmp_bg.png';
const cp      = require('child_process');
const screenp = cp.spawnSync('screencapture', ['-x', bg_loc]);

const sizep  = cp.spawnSync('sh', ['-c', 'system_profiler SPDisplaysDataType | grep -Eoh "[0-9]{4} x [0-9]{4}" | tr -d [:space:]' ]);
var size_tmp = sizep.stdout.toString().split('x');

const electron      = require('electron');
const app           = electron.app;
const BrowserWindow = electron.BrowserWindow;
var   mainWindow    = null;

app.on('window-all-closed', function() {
  app.quit();
});

app.on('ready', function() {
  mainWindow = new BrowserWindow({
    width                  : parseInt(size_tmp[0]),
    height                 : parseInt(size_tmp[1]),
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
