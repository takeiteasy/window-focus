'use strict';

const cp            = require('child_process');
const electron      = require('electron'),
      app           = electron.app,
      BrowserWindow = electron.BrowserWindow;

const sizep   = cp.spawnSync('sh', ['-c', 'system_profiler SPDisplaysDataType | \
                                           grep -Eoh "[0-9]{4} x [0-9]{4}"']).stdout.toString().split('\n').map((x) =>{
                                             return x.split(' x ');
                                           }).slice(0, -1);

const bg_loc  = '/tmp/tmp_bg_';
cp.spawnSync('screencapture', ['-x'].concat(Array.apply(null, { length: sizep.length }).map((x, i) => {
  return bg_loc + i.toString() + '.png';
})));

function run_applescript(cmd) {
  const x = cp.spawnSync('osascript', ['-e', cmd]);
  return [ x.stdout.toString(), x.stderr.toString() ];
}

function get_activewin() {
  return run_applescript('tell application "System Events" to return name of first application process whose frontmost is true')[0].slice(0, -1);
}

var target_proc   = null;
if (process.argv.length <= 2)
  target_proc = get_activewin();
else
  target_proc = process.argv[2];

app.on('window-all-closed', function() {
  app.quit();
});

app.on('ready', function() {
  const screen = electron.screen;
  const displays = screen.getAllDisplays();
  console.log(displays);

  var windows = [];
  for (let x = 0; x < displays.length; ++x) {
    var win_x = new BrowserWindow({
      width                  : displays[x].bounds.width,
      height                 : displays[x].bounds.height,
      transparent            : true,
      frame                  : false,
      moveable               : false,
      resizable              : false,
      enableLargerThanScreen : true,
      x                      : displays[x].bounds.x,
      y                      : displays[x].bounds.y
    });
    win_x.loadURL('file://' + __dirname + '/index.html?v=' + x.toString());

    win_x.on('closed', () => {
      app.quit();
    }).on(   'focus',  () => {
      app.quit();
    });
  }

  if (run_applescript('\
tell application "' + target_proc + '"\n\
  if it is running then\n\
    activate \n\
  else\n\
    tell application "System Events"\n\
      set frontmost of process "' + target_proc + '" to true\n\
    end tell\n\
  end if\n\
end tell')[1].length > 0) {
    console.log('No valid application/process "' + target_proc + '"');
    app.quit();
  } else
    target_proc = get_activewin();

  setInterval(() => {
    if (get_activewin() != target_proc)
      app.quit();
  }, 1);
});
