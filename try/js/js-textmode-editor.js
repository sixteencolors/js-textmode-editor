(function() {
  var AbortParse, CharacterSets, Cursor, FileSelectHandler, Palette, ParseFile, editor,
    __hasProp = {}.hasOwnProperty;

  this.Editor = (function() {
    var key;

    key = {
      left: 37,
      up: 38,
      right: 39,
      down: 40,
      f1: 112,
      f2: 113,
      f3: 114,
      f4: 115,
      f5: 116,
      f6: 117,
      f7: 118,
      f8: 119,
      f9: 120,
      f10: 121,
      backspace: 8,
      "delete": 46,
      end: 35,
      home: 36,
      enter: 13,
      escape: 27,
      insert: 45,
      h: 72,
      l: 76,
      s: 83,
      ctrlF: 6,
      ctrlB: 2,
      ctrlX: 24,
      ctrlC: 3
    };

    function Editor(options) {
      var k, v;
      this.tabstop = 8;
      this.id = 'canvas';
      this.vga_id = 'vga';
      this.vga_scale = '.25';
      this.columns = 80;
      for (k in options) {
        if (!__hasProp.call(options, k)) continue;
        v = options[k];
        this[k] = v;
      }
    }

    Editor.prototype.dbAuthenticate = function() {
      var _this = this;
      return this.dbClient.authenticate({
        interactive: false
      }, function(error, client) {
        if (error) {
          return _this.showError(error);
        }
        if (client.isAuthenticated()) {
          $("#DropboxSaveContainer").show();
          $("#DropboxFiles").show();
          $(".dropbox-login").hide();
          return $('#user-name').text(userInfo.name);
        } else {
          $("#DropboxSaveContainer").hide();
          $("#DropboxFiles").hide();
          $(".dropbox-login").show();
          return $(".dropbox-login").click(function() {
            return client.authenticate(function(error, client) {
              if (error) {
                return _this.showError(error);
              }
              return client.getUserInfo(function(error, userInfo) {
                if (error && window.console) {
                  console.log(error);
                }
                $("#DropboxFiles").show();
                $("#DropboxSaveContainer").show();
                $(".dropbox-login").hide();
                $('#user-name').text(userInfo.name);
                _this.updateDrawingList();
                if (window.console) {
                  return console.log("authenticated to dropbox as " + userInfo.name);
                }
              });
            });
          });
        }
      });
    };

    Editor.prototype.showError = function(error) {
      $('#ErrorDialog').slideToggle('slow');
      $("#ErrorDialog .message").text(error);
      if (window.console) {
        return console.log(error);
      }
    };

    Editor.prototype.init = function() {
      var _this = this;
      this.image = new ImageTextModeANSI;
      this.dbClient = new Dropbox.Client({
        key: config.dropbox.key,
        sandbox: true
      });
      this.dbClient.authDriver(new Dropbox.Drivers.Popup({
        rememberUser: true,
        receiverFile: "oauth_receiver.html"
      }));
      this.dbAuthenticate();
      this.canvas = document.getElementById(this.id);
      this.width = this.image.font.width * this.columns;
      this.canvas.setAttribute('width', this.width);
      this.vga_canvas = document.getElementById(this.vga_id);
      this.vga_canvas.setAttribute('width', this.width * this.vga_scale);
      this.drawingId = null;
      this.block = {
        start: {
          x: 0,
          y: 0
        },
        end: {
          x: 0,
          y: 0
        },
        mode: 'off'
      };
      this.drawings = $.parseJSON($.Storage.get("drawings"));
      this.cursor = new Cursor;
      this.cursor.init(this);
      this.pal = new Palette;
      this.pal.init(this);
      this.sets = new CharacterSets;
      this.sets.init(this);
      if (this.canvas.getContext) {
        this.ctx = this.canvas.getContext('2d');
      }
      if (this.vga_canvas.getContext) {
        this.vga_ctx = this.vga_canvas.getContext('2d');
      }
      this.setHeight($(window).height() + this.image.font.height);
      this.draw();
      $('#clear').click(function() {
        var answer;
        answer = confirm('Clear canvas?');
        if (answer) {
          _this.drawingId = null;
          _this.image.screen = [];
          _this.draw();
          return _this.setName("");
        }
      });
      $('#save').click(function() {
        _this.toggleSaveDialog();
        if (!_this.drawings) {
          _this.drawings = [];
        }
        if (_this.drawings[_this.drawingId]) {
          _this.setName(_this.drawings[_this.drawingId].name);
        }
        return _this.dbAuthenticate();
      });
      $('#html5Save').click(function() {
        _this.drawings[_this.getId()] = {
          grid: _this.image.screen,
          date: new Date(),
          name: $('#name').val()
        };
        $.Storage.set("drawings", JSON.stringify(_this.drawings));
        return _this.toggleSaveDialog();
      });
      $('#PNGSave').click(function() {
        return window.open(_this.canvas.toDataURL("image/png"), 'ansiSave');
      });
      $('#DropboxSave').click(function() {
        return _this.dbClient.writeFile('ansi/' + $('#name').val(), _this.image.write(), function(error, stat) {
          if (error) {
            return _this.showError(error);
          }
          return _this.toggleSaveDialog();
        });
      });
      $('#load').click(function() {
        return _this.toggleLoadDialog();
      });
      $("#canvasscroller").scroll(function(e) {
        if (e.target.clientHeight + _this.getScrollOffset() >= _this.height) {
          _this.setHeight(_this.height + _this.image.font.height);
        }
        _this.cursor.draw();
        if (_this.cursor.mousedown) {
          $(_this).trigger("moveblock");
        }
        return $("#vgahighlight").css('top', _this.getScrollOffset() * _this.vga_scale);
      });
      $("body").bind("keyup", function(e) {
        var _ref;
        if (_this.block.mode === 'on' && !e.shiftKey && ((_ref = e.which) !== key.shift && _ref !== key.ctrl && _ref !== key["delete"] && _ref !== key.backspace)) {
          return $(_this).trigger("endblock");
        }
      });
      $("body").bind("keydown", function(e) {
        var mod, oldrow, prevention, _ref, _ref1, _ref2;
        prevention = false;
        if (_this.block.mode && ((_ref = e.which) === key["delete"] || _ref === key.backspace)) {
          return _this["delete"]();
        } else if (e.target.nodeName !== "INPUT") {
          mod = e.altKey || e.ctrlKey;
          if (e.shiftKey && ((e.which >= key.left && e.which <= key.down) || (e.which >= key.end && e.which <= key.home))) {
            if (_this.block.mode === 'off') {
              $(_this).trigger("startblock", [_this.cursor.x, _this.cursor.y, _this.getLinesOffset()]);
            }
          }
          switch (e.which) {
            case key.left:
              if (!mod) {
                _this.cursor.moveLeft();
              } else if (e.ctrlKey || e.shiftKey) {
                if (_this.pal.bg < 7) {
                  _this.pal.bg++;
                } else {
                  _this.pal.bg = 0;
                }
              }
              break;
            case key.right:
              if (!mod) {
                _this.cursor.moveRight();
              } else if (e.ctrlKey || e.shiftKey) {
                if (_this.pal.bg > 0) {
                  _this.pal.bg--;
                } else {
                  _this.pal.bg = 7;
                }
              }
              break;
            case key.down:
              prevention = true;
              if (!mod) {
                _this.cursor.moveDown();
              } else if (e.ctrlKey) {
                if (_this.pal.fg < 15) {
                  _this.pal.fg++;
                } else {
                  _this.pal.fg = 0;
                }
              }
              break;
            case key.up:
              prevention = true;
              if (!mod) {
                _this.cursor.moveUp();
              } else if (e.ctrlKey) {
                if (_this.pal.fg > 0) {
                  _this.pal.fg--;
                } else {
                  _this.pal.fg = 15;
                }
              }
              break;
            case key.backspace:
              _this.cursor.moveLeft();
              if (_this.cursor.mode === 'ovr') {
                _this.putChar(32);
                _this.cursor.moveLeft();
              } else {
                oldrow = _this.image.screen[_this.cursor.y];
                _this.image.screen[_this.cursor.y] = oldrow.slice(0, +(_this.cursor.x - 1) + 1 || 9e9).concat(oldrow.slice(_this.cursor.x + 1, +(oldrow.length - 1) + 1 || 9e9));
              }
              e.preventDefault();
              break;
            case key["delete"]:
              oldrow = _this.image.screen[_this.cursor.y];
              _this.image.screen[_this.cursor.y] = oldrow.slice(0, +(_this.cursor.x - 1) + 1 || 9e9).concat(oldrow.slice(_this.cursor.x + 1, +(oldrow.length - 1) + 1 || 9e9));
              break;
            case key.end:
              _this.cursor.x = parseInt(_this.width / _this.image.font.width - 1);
              break;
            case key.home:
              _this.cursor.x = 0;
              break;
            case key.enter:
              if ((_ref1 = _this.block.mode) === 'copy' || _ref1 === 'cut') {
                _this.paste();
              } else {
                _this.cursor.x = 0;
                _this.cursor.y++;
              }
              break;
            case key.insert:
              _this.cursor.change_mode();
              break;
            case key.escape:
              if ($('#splash').is(':visible')) {
                $('#splash').slideToggle('slow');
              }
              if ($('#drawings').is(':visible')) {
                $('#drawings').slideToggle('slow');
              }
              if ($('#SaveDialog').is(':visible')) {
                $('#SaveDialog').slideToggle('slow');
              }
              if ($('#ErrorDialog').is(':visible')) {
                $('#ErrorDialog').slideToggle('slow');
              }
              if ((_ref2 = _this.block.mode) === 'copy' || _ref2 === 'cut') {
                if (_this.block.mode === 'cut') {
                  _this.cancelCut();
                }
                $('#copy').remove();
                $(_this).trigger("endblock");
              }
              break;
            default:
              if (e.which === key.h && e.altKey) {
                _this.toggleHelpDialog();
                e.preventDefault();
              }
              if (e.which === key.l && e.altKey) {
                _this.updateDrawingList();
                _this.toggleLoadDialog();
                e.preventDefault();
              }
              if (e.which === key.s && e.altKey) {
                _this.toggleSaveDialog();
                e.preventDefault();
              } else if (e.which >= 112 && e.which <= 121) {
                if (!e.altKey && !e.shiftKey && !e.ctrlKey) {
                  _this.putChar(_this.sets.sets[_this.sets.set][e.which - 112]);
                } else if (e.altKey) {
                  _this.sets.set = e.which - 112;
                  _this.sets.fadeSet();
                }
                e.preventDefault();
              }
          }
          _this.updateCursorPosition();
          if (e.shiftKey && ((e.which >= key.left && e.which <= key.down) || (e.which >= key.end && e.which <= key.home)) && _this.block.mode === 'on') {
            $(_this).trigger("moveblock");
          }
          _this.pal.draw();
          _this.cursor.draw();
          if (prevention) {
            e.preventDefault;
            return false;
          }
        }
      });
      if (document.all) {
        window.onhelp = function() {
          return false;
        };
        document.onhelp = function() {
          return false;
        };
      }
      $(this).bind("startblock", function(e, x, y, offset) {
        _this.block = {
          start: {
            x: x,
            y: y,
            offset: offset
          },
          end: {
            x: x,
            y: y,
            offset: offset
          },
          mode: 'on'
        };
        $("#highlight").css('display', 'block');
        return $(_this).trigger("moveblock");
      });
      $(this).bind("endblock", function(e) {
        _this.block.mode = 'off';
        $("#highlight").css('display', 'none');
        return _this.copyGrid = [];
      });
      $(this).bind("moveblock", function(e) {
        var adjustedStartY;
        adjustedStartY = _this.block.start.y + _this.block.start.offset - _this.getLinesOffset();
        $("#highlight").css('left', (_this.cursor.x >= _this.block.start.x ? _this.block.start.x : _this.cursor.x) * _this.image.font.width);
        $("#highlight").css('top', (_this.cursor.y >= adjustedStartY ? adjustedStartY : _this.cursor.y) * _this.image.font.height);
        $("#highlight").width((Math.abs(_this.cursor.x - _this.block.start.x) + 1) * _this.image.font.width);
        return $("#highlight").height((Math.abs(_this.cursor.y - adjustedStartY) + 1) * _this.image.font.height);
      });
      $("body").bind("keypress", function(e) {
        var char, pattern;
        if (_this.block.mode === 'on' && e.ctrlKey) {
          switch (e.which) {
            case key.ctrlF:
              _this.fillBlock(_this.pal.fg, null);
              return _this.draw();
            case key.ctrlB:
              _this.fillBlock(null, _this.pal.bg);
              return _this.draw();
            case key.ctrlX:
              _this.setBlockEnd();
              return _this.cut();
            case key.ctrlC:
              _this.setBlockEnd();
              return _this.copy();
          }
        } else if (e.target.nodeName !== "INPUT") {
          char = String.fromCharCode(e.which);
          pattern = /[\w!@\#$%^&*()_+=\\|\[\]\{\},\.<>\/\?`~\-\s]/;
          if (char.match(pattern) && e.which <= 255 && !e.ctrlKey && e.which !== 13) {
            return _this.putChar(char.charCodeAt(0) & 255);
          }
        }
      });
      $('#' + this.id).mousemove(function(e) {
        var _ref;
        if (_this.cursor.mousedown) {
          _this.setMouseCoordinates(e);
          if (_this.sets.locked) {
            _this.putChar(_this.sets.char, true);
          }
          _this.updateCursorPosition();
          if (_this.block.mode === 'off' && !sets.locked) {
            $(_this).trigger("startblock", [_this.cursor.x, _this.cursor.y, _this.getLinesOffset()]);
          } else if (!_this.sets.locked) {
            $(_this).trigger("moveblock");
          }
          return true;
        }
        if ((_ref = _this.block.mode) === 'copy' || _ref === 'cut') {
          _this.setMouseCoordinates(e);
          return _this.positionCopy();
        }
      });
      $('#' + this.id).mousedown(function(e) {
        var _ref;
        if (e.which !== 1) {
          return;
        }
        _this.cursor.mousedown = true;
        _this.cursor.x = Math.floor((e.pageX - $('#' + _this.id).offset().left) / _this.image.font.width);
        _this.cursor.y = Math.floor((e.pageY - $('#' + _this.id).offset().top) / _this.image.font.height);
        if (_this.sets.locked) {
          _this.putChar(_this.sets.char, true);
        }
        _this.cursor.draw();
        _this.updateCursorPosition();
        if ((_ref = _this.block.mode) !== 'copy' && _ref !== 'cut') {
          $(_this).trigger("endblock");
        }
        return true;
      });
      $('#' + this.id).bind('touchstart', function(e) {
        e.preventDefault();
        if (e.originalEvent.touches.length === 1) {
          return _this.putTouchChar(e.originalEvent.touches[0]);
        }
      });
      $('#' + this.id).bind('touchmove', function(e) {
        var touch;
        if (e.originalEvent.touches.length === 1) {
          touch = e.originalEvent.touches[0];
          return _this.putTouchChar(touch);
        }
      });
      $('body').mouseup(function(e) {
        var _ref;
        if ((_ref = _this.block.mode) === 'copy' || _ref === 'cut') {
          _this.paste();
        }
        _this.cursor.mousedown = false;
        return _this.cursor.draw();
      });
      return $(window).resize(function(e) {
        _this.width = _this.canvas.clientWidth;
        _this.height = _this.canvas.clientHeight;
        _this.canvas.setAttribute('width', _this.width);
        _this.canvas.setAttribute('height', _this.height);
        return _this.draw();
      });
    };

    Editor.prototype.getScrollOffset = function() {
      return $("#canvasscroller").scrollTop();
    };

    Editor.prototype.getLinesOffset = function() {
      return Math.floor(this.getScrollOffset() / this.image.font.height);
    };

    Editor.prototype.setHeight = function(height, copy) {
      var tempCanvas, tempImg,
        _this = this;
      if (copy == null) {
        copy = true;
      }
      $('#canvaswrapper').height($(window).height());
      $('#canvasscroller').height($(window).height());
      if (height < $(window).height() + this.image.font.height) {
        height = $(window).height() + this.image.font.height;
      }
      if (height > this.height || !(this.height != null)) {
        this.height = height;
        if (copy) {
          tempCanvas = this.canvas.toDataURL("image/png");
          tempImg = new Image();
          tempImg.src = tempCanvas;
          $(tempImg).load(function() {
            _this.canvas.setAttribute('height', _this.height);
            _this.ctx.drawImage(tempImg, 0, 0);
            return _this.renderCanvas();
          });
        } else {
          this.canvas.setAttribute('height', this.height);
        }
        this.vga_canvas.setAttribute('height', this.height);
        return console.log("Height updated to " + this.height + "px");
      }
    };

    Editor.prototype.setBlockEnd = function() {
      this.block.end.y = this.cursor.y;
      return this.block.end.x = this.cursor.x;
    };

    Editor.prototype.copy = function() {
      this.block.mode = 'copy';
      return this.copyOrCut();
    };

    Editor.prototype.cut = function() {
      this.block.mode = 'cut';
      return this.copyOrCut(true, true);
    };

    Editor.prototype["delete"] = function() {
      this.copyOrCut(false, true);
      return $(this).trigger("endblock");
    };

    Editor.prototype.cancelCut = function() {
      var endx, endy, startx, starty, x, xx, y, yy, _i, _j;
      if (this.block.end.y > this.block.start.y) {
        starty = this.block.start.y;
        endy = this.block.end.y;
      } else {
        starty = this.block.end.y;
        endy = this.block.start.y;
      }
      if (this.block.end.x > this.block.start.x) {
        startx = this.block.start.x;
        endx = this.block.end.x;
      } else {
        startx = this.block.end.x;
        endx = this.block.start.x;
      }
      yy = 0;
      for (y = _i = starty; starty <= endy ? _i <= endy : _i >= endy; y = starty <= endy ? ++_i : --_i) {
        xx = 0;
        for (x = _j = startx; startx <= endx ? _j <= endx : _j >= endx; x = startx <= endx ? ++_j : --_j) {
          if (this.copyGrid[yy][xx] != null) {
            this.image.screen[y][x] = {
              ch: this.copyGrid[yy][xx].ch,
              attr: this.copyGrid[yy][xx].attr
            };
          }
          xx++;
        }
        yy++;
      }
      $('#copy').remove();
      return this.draw();
    };

    Editor.prototype.copyOrCut = function(copy, cut) {
      var adjustedStartY, adjustedY, destHeight, destWidth, destX, destY, endx, endy, sourceHeight, sourceWidth, sourceX, sourceY, startx, starty, x, xx, y, yy, _i, _j;
      if (copy == null) {
        copy = true;
      }
      if (cut == null) {
        cut = false;
      }
      this.copyGrid = [];
      if (this.cursor.y > this.block.start.y) {
        starty = this.block.start.y;
        endy = this.cursor.y;
      } else {
        starty = this.cursor.y;
        endy = this.block.start.y;
      }
      if (this.cursor.x > this.block.start.x) {
        startx = this.block.start.x;
        endx = this.cursor.x;
      } else {
        startx = this.cursor.x;
        endx = this.block.start.x;
      }
      if (copy) {
        adjustedStartY = this.block.start.y + this.block.start.offset;
        adjustedY = this.cursor.y + this.getLinesOffset();
        sourceWidth = (Math.abs(this.cursor.x - this.block.start.x) + 1) * this.image.font.width;
        sourceHeight = (Math.abs(adjustedY - adjustedStartY) + 1) * this.image.font.height;
        this.copyCanvas = document.createElement('canvas');
        this.copyCanvas.id = 'copy';
        if (this.copyCanvas.getContext) {
          this.copyCanvasContext = this.copyCanvas.getContext('2d');
        }
        this.copyCanvas.setAttribute('width', sourceWidth);
        this.copyCanvas.setAttribute('height', sourceHeight);
        this.cursor.x = this.cursor.x >= this.block.start.x ? this.block.start.x : this.cursor.x;
        this.cursor.y = adjustedY >= adjustedStartY ? adjustedStartY : adjustedY;
        sourceX = this.cursor.x * this.image.font.width;
        sourceY = this.cursor.y * this.image.font.height;
        this.cursor.y -= this.getLinesOffset();
        destWidth = sourceWidth;
        destHeight = sourceHeight;
        destX = 0;
        destY = 0;
        this.copyCanvasContext.drawImage(this.canvas, sourceX, sourceY, sourceWidth, sourceHeight, destX, destY, destWidth, destHeight);
        $(this.copyCanvas).insertBefore('#vga');
      }
      yy = 0;
      for (y = _i = starty; starty <= endy ? _i <= endy : _i >= endy; y = starty <= endy ? ++_i : --_i) {
        xx = 0;
        for (x = _j = startx; startx <= endx ? _j <= endx : _j >= endx; x = startx <= endx ? ++_j : --_j) {
          if (!(this.copyGrid[yy] != null)) {
            this.copyGrid[yy] = [];
          }
          if ((this.image.screen[y][x] != null) && copy) {
            this.copyGrid[yy][xx] = {
              ch: this.image.screen[y][x].ch,
              attr: this.image.screen[y][x].attr
            };
          }
          if (cut && (this.image.screen[y][x] != null)) {
            this.image.screen[y][x] = {
              ch: ' ',
              attr: (0 << 4) | 0
            };
          }
          xx++;
        }
        yy++;
      }
      if (cut) {
        this.draw();
      }
      return this.positionCopy();
    };

    Editor.prototype.paste = function() {
      var stationaryX, stationaryY, x, y, _i, _j, _ref, _ref1;
      stationaryY = this.cursor.y;
      stationaryX = this.cursor.x;
      for (y = _i = 0, _ref = this.copyGrid.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; y = 0 <= _ref ? ++_i : --_i) {
        if (!(this.copyGrid[y] != null)) {
          continue;
        }
        for (x = _j = 0, _ref1 = this.copyGrid[y].length - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          if (!(this.copyGrid[y][x] != null)) {
            continue;
          }
          if (!(this.image.screen[stationaryY + y] != null)) {
            this.image.screen[stationaryY + y] = [];
          }
          if (this.copyGrid[y][x] != null) {
            this.image.screen[stationaryY + y][stationaryX + x] = {
              ch: this.copyGrid[y][x].ch,
              attr: this.copyGrid[y][x].attr
            };
          }
        }
      }
      this.draw();
      $('#copy').remove();
      return $(this).trigger("endblock");
    };

    Editor.prototype.setMouseCoordinates = function(e) {
      this.cursor.x = Math.floor((e.pageX - $('#' + this.id).offset().left) / this.image.font.width);
      return this.cursor.y = Math.floor(e.pageY / this.image.font.height);
    };

    Editor.prototype.positionCopy = function() {
      $(this.copyCanvas).css('left', this.cursor.x * this.image.font.width);
      return $(this.copyCanvas).css('top', this.cursor.y * this.image.font.height);
    };

    Editor.prototype.fillBlock = function(fg, bg) {
      var x, y, _i, _ref, _ref1, _results;
      _results = [];
      for (y = _i = _ref = this.block.start.y, _ref1 = this.cursor.y; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; y = _ref <= _ref1 ? ++_i : --_i) {
        if (!(this.image.screen[y] != null)) {
          continue;
        }
        _results.push((function() {
          var _j, _ref2, _ref3, _results1;
          _results1 = [];
          for (x = _j = _ref2 = this.cursor.x, _ref3 = this.block.start.x; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; x = _ref2 <= _ref3 ? ++_j : --_j) {
            if (!(this.image.screen[y][x] != null)) {
              continue;
            }
            _results1.push(this.image.screen[y][x].attr = ((bg ? bg : (this.image.screen[y][x].attr & 240) >> 4) << 4) | (fg ? fg : this.image.screen[y][x].attr & 15));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Editor.prototype.setName = function(name) {
      return $('#name').val(name);
    };

    Editor.prototype.toggleSaveDialog = function() {
      if (!$('#SaveDialog').is(':visible')) {
        $('#drawings').slideUp('slow');
        $('#splash').slideUp('slow');
      }
      return $('#SaveDialog').slideToggle('slow');
    };

    Editor.prototype.toggleLoadDialog = function() {
      if (!$('#drawings').is(':visible')) {
        this.updateDrawingList();
        $('#SaveDialog').slideUp('slow');
        $('#splash').slideUp('slow');
      }
      return $('#drawings').slideToggle('slow');
    };

    Editor.prototype.toggleHelpDialog = function() {
      if (!$('#splash').is(':visible')) {
        $('#drawings').slideUp('slow');
        $('#SaveDialog').slideUp('slow');
      }
      return $('#splash').slideToggle('slow');
    };

    Editor.prototype.updateDrawingList = function() {
      var drawing, i, _i, _len, _ref,
        _this = this;
      $('#drawings #html5Files ol').empty();
      if (!this.drawings) {
        this.drawings = [];
      }
      _ref = this.drawings;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        drawing = _ref[i];
        this.addDrawing(drawing, i);
      }
      $('#drawings #html5Files li span.name').click(function(e) {
        _this.drawingId = $(e.currentTarget).parent().attr("nid");
        _this.image.screen = _this.drawings[_this.drawingId].grid;
        _this.height = 0;
        _this.setHeight(_this.image.screen.length * _this.image.font.height, false);
        _this.draw();
        return _this.toggleLoadDialog();
      });
      $('#drawings #html5Files li span.delete').click(function(e) {
        var answer;
        answer = confirm('Delete drawing?');
        if (answer) {
          _this.drawings[$(e.currentTarget).parent().attr("nid")] = null;
          $.Storage.set("drawings", JSON.stringify(_this.drawings));
          return _this.updateDrawingList();
        }
      });
      if (this.dbClient.isAuthenticated()) {
        $("#drawings #DropboxFiles").empty();
        return this.dbClient.mkdir('/ansi', function(error, stat) {
          return _this.dbClient.readdir('/ansi', function(error, entries, dir_stat, entry_stats) {
            var entry, _j, _len1;
            if (error && window.console) {
              console.log(error);
            }
            for (_j = 0, _len1 = entry_stats.length; _j < _len1; _j++) {
              entry = entry_stats[_j];
              $('#DropboxFiles').append("<li nid=\"" + entry.name + "\"><span class=\"name\">" + entry.name + "</span> <span class=\"delete\"></span>");
            }
            return $('#DropboxFiles span.name').click(function(e) {
              return _this.dbClient.readFile("ansi/" + ($(e.target).text()), {
                arrayBuffer: true
              }, function(error, data) {
                if (error) {
                  return _this.showError(error);
                }
                _this.image.parse(_this.binaryArrayToString(data));
                _this.setHeight(_this.image.getHeight() * _this.image.font.height, false);
                _this.draw();
                return _this.toggleLoadDialog();
              });
            });
          });
        });
      }
    };

    Editor.prototype.addDrawing = function(drawing, id) {
      if (drawing) {
        return $('#drawings #html5Files ol').append('<li nid=' + id + '><span class="name">' + (drawing.name ? drawing.name : $.format.date(drawing.date, "MM/dd/yyyy hh:mm:ss a")) + '</span> <span class="delete">X</span></li>');
      }
    };

    Editor.prototype.getId = function() {
      if (this.drawingId) {
        return this.drawingId;
      } else {
        return this.generateId();
      }
    };

    Editor.prototype.generateId = function() {
      if (this.drawings) {
        return this.drawings.length;
      } else {
        return 1;
      }
    };

    Editor.prototype.updateCursorPosition = function() {
      return $('#cursorpos').text('(' + (this.cursor.x + 1) + ', ' + (this.cursor.y + 1) + ')');
    };

    Editor.prototype.putTouchChar = function(touch) {
      var node;
      node = touch.target;
      this.cursor.x = Math.floor((touch.pageX - $('#' + this.id).offset().left) / this.image.font.width);
      this.cursor.y = Math.floor((touch.pageY - $('#' + this.id).offset().top) / this.image.font.height);
      if (this.sets.locked) {
        this.putChar(this.sets.char);
      }
      this.drawChar(this.cursor.x, this.cursor.y);
      this.updateCursorPosition();
      return true;
    };

    Editor.prototype.putChar = function(charCode, holdCursor) {
      var row, _ref;
      if (holdCursor == null) {
        holdCursor = false;
      }
      if (!this.image.screen[this.cursor.y]) {
        this.image.screen[this.cursor.y] = [];
      }
      if (this.cursor.mode === 'ins') {
        row = this.image.screen[this.cursor.y].slice(this.cursor.x);
        [].splice.apply(this.image.screen[this.cursor.y], [(_ref = this.cursor.x + 1), 9e9].concat(row)), row;
      }
      this.image.screen[this.cursor.y][this.cursor.x] = {
        ch: String.fromCharCode(charCode),
        attr: (this.pal.bg << 4) | this.pal.fg
      };
      this.drawChar(this.cursor.x, this.cursor.y);
      if (!holdCursor) {
        this.cursor.moveRight();
      }
      return this.updateCursorPosition();
    };

    Editor.prototype.loadUrl = function(url) {
      var content, req;
      req = new XMLHttpRequest;
      req.open('GET', url, false);
      if (req.overrideMimeType) {
        req.overrideMimeType('text/plain; charset=x-user-defined');
      }
      req.send(null);
      content = req.status === 200 || req.status === 0 ? req.responseText : '';
      return content;
    };

    Editor.prototype.loadFont = function() {
      return new ImageTextModeFont8x16;
    };

    Editor.prototype.drawChar = function(x, y, full) {
      var chr, i, j, line, px, py, _i, _j, _ref, _ref1;
      if (full == null) {
        full = false;
      }
      if (this.image.screen[y][x]) {
        px = x * this.image.font.width;
        py = y * this.image.font.height;
        this.ctx.fillStyle = this.pal.toRgbaString(this.image.palette.colors[(this.image.screen[y][x].attr & 240) >> 4]);
        this.ctx.fillRect(px, py, 8, 16);
        this.ctx.fillStyle = this.pal.toRgbaString(this.image.palette.colors[this.image.screen[y][x].attr & 15]);
        chr = this.image.font.chars[this.image.screen[y][x].ch.charCodeAt(0) & 0xff];
        for (i = _i = 0, _ref = this.image.font.height - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          line = chr[i];
          for (j = _j = 0, _ref1 = this.image.font.width - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
            if (line & (1 << 7 - j)) {
              this.ctx.fillRect(px + j, py + i, 1, 1);
            }
          }
        }
        if (!full) {
          return this.renderCanvas();
        }
      }
    };

    Editor.prototype.draw = function() {
      var x, y, _i, _j, _ref, _ref1;
      this.ctx.fillStyle = "#000000";
      this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
      for (y = _i = 0, _ref = this.image.screen.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; y = 0 <= _ref ? ++_i : --_i) {
        if (!(this.image.screen[y] != null)) {
          continue;
        }
        for (x = _j = 0, _ref1 = this.image.screen[y].length - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
          if (!(this.image.screen[y][x] != null)) {
            continue;
          }
          this.drawChar(x, y, true);
        }
      }
      return this.renderCanvas();
    };

    Editor.prototype.renderCanvas = function() {
      var highlight;
      this.ctx.fill();
      this.vga_ctx.fillStyle = "#000000";
      this.vga_ctx.fillRect(0, 0, this.canvas.width * this.vga_scale, this.canvas.height * this.vga_scale);
      this.vga_ctx.drawImage(this.canvas, 0, 0, this.canvas.width, this.canvas.height, 0, 0, this.canvas.width * this.vga_scale, this.canvas.height * this.vga_scale);
      highlight = $("#vgahighlight");
      highlight.width(this.vga_canvas.getAttribute('width'));
      highlight.height($("#canvaswrapper").height() * this.vga_scale);
      return $("#vgawrapper").css('left', $("#toolbar").width() + $("#canvas").width());
    };

    Editor.prototype.binaryArrayToString = function(buf) {
      return String.fromCharCode.apply(null, new Uint8Array(buf));
    };

    return Editor;

  })();

  Cursor = (function() {

    function Cursor(options) {
      var k, v;
      this.x = 0;
      this.y = 0;
      this.mousedown = false;
      this.mode = 'ovr';
      this.selector = $('#cursor');
      this.offset = 0;
      for (k in options) {
        if (!__hasProp.call(options, k)) continue;
        v = options[k];
        this[k] = v;
      }
    }

    Cursor.prototype.init = function(editor) {
      this.editor = editor;
      return this.draw();
    };

    Cursor.prototype.change_mode = function(mode) {
      if (mode) {
        this.selector.attr('class', mode);
      } else {
        this.selector.toggleClass('ins');
      }
      return this.mode = this.selector.attr('class') || 'ovr';
    };

    Cursor.prototype.draw = function() {
      var height, width;
      width = this.editor.image.font.width;
      height = this.editor.image.font.height;
      this.selector.css('width', width);
      this.selector.css('height', height);
      this.selector.css('left', this.x * width);
      return this.selector.css('top', this.y * height - this.editor.getScrollOffset());
    };

    Cursor.prototype.moveRight = function() {
      if (this.x < this.editor.width / this.editor.image.font.width - 1) {
        this.x++;
      } else if (this.y < this.editor.height / this.editor.image.font.height - 1) {
        this.x = 0;
        this.y++;
      }
      return this.move();
    };

    Cursor.prototype.moveLeft = function() {
      if (this.x > 0) {
        this.x--;
      } else if (this.y > 0) {
        this.y--;
        this.x = this.editor.width / this.editor.image.font.width - 1;
      }
      return this.move();
    };

    Cursor.prototype.moveUp = function() {
      if (this.y > 0) {
        this.y--;
      }
      if (this.y * this.editor.image.font.height < this.getScrollOffset()) {
        $("#canvasscroller").scrollTop(this.getScrollOffset() - this.editor.image.font.height);
      }
      return this.move();
    };

    Cursor.prototype.moveDown = function() {
      if (this.y >= parseInt(($(window).height() - this.editor.image.font.height * 2) / this.editor.image.font.height)) {
        $("#canvasscroller").scrollTop(this.getScrollOffset() + this.editor.image.font.height);
      }
      this.y++;
      return this.move();
    };

    Cursor.prototype.move = function() {
      var _ref;
      if ((_ref = this.editor.block.mode) === 'copy' || _ref === 'cut') {
        this.editor.positionCopy();
      }
      return this.draw();
    };

    return Cursor;

  })();

  CharacterSets = (function() {

    function CharacterSets(options) {
      var k, v;
      this.sets = [[218, 191, 192, 217, 196, 179, 195, 180, 193, 194], [201, 187, 200, 188, 205, 186, 204, 185, 202, 203], [213, 184, 212, 190, 205, 179, 198, 181, 207, 209], [214, 183, 211, 189, 196, 186, 199, 182, 208, 210], [197, 206, 216, 215, 232, 232, 155, 156, 153, 239], [176, 177, 178, 219, 223, 220, 221, 222, 254, 250], [1, 2, 3, 4, 5, 6, 240, 14, 15, 32], [24, 25, 30, 31, 16, 17, 18, 29, 20, 21], [174, 175, 242, 243, 169, 170, 253, 246, 171, 172], [227, 241, 244, 245, 234, 157, 228, 248, 251, 252], [224, 225, 226, 229, 230, 231, 235, 236, 237, 238], [128, 135, 165, 164, 152, 159, 247, 249, 173, 168], [131, 132, 133, 160, 166, 134, 142, 143, 145, 146], [136, 137, 138, 130, 144, 140, 139, 141, 161, 158], [147, 148, 149, 162, 167, 150, 129, 151, 163, 154]];
      this.set = 5;
      this.charpos = 0;
      this.char = this.sets[this.set][this.charpos];
      this.locked = false;
      for (k in options) {
        if (!__hasProp.call(options, k)) continue;
        v = options[k];
        this[k] = v;
      }
    }

    CharacterSets.prototype.init = function(editor) {
      var c, char, chars, charwrap, ctx, i, j, line, set, x, y, _i, _j, _k, _l, _ref, _ref1, _ref2, _ref3,
        _this = this;
      for (i = _i = 0, _ref = this.sets.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        set = $('<li>');
        set.data('set', i);
        chars = $('<ul>');
        for (j = _j = 0, _ref1 = this.sets[i].length - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
          c = this.sets[i][j];
          char = $('<canvas>');
          char.attr('width', editor.image.font.width);
          char.attr('height', editor.image.font.height);
          ctx = char[0].getContext('2d');
          ctx.fillStyle = '#fff';
          for (y = _k = 0, _ref2 = editor.image.font.height - 1; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; y = 0 <= _ref2 ? ++_k : --_k) {
            line = editor.image.font.chars[c][y];
            for (x = _l = 0, _ref3 = editor.image.font.width - 1; 0 <= _ref3 ? _l <= _ref3 : _l >= _ref3; x = 0 <= _ref3 ? ++_l : --_l) {
              if (line & (1 << 7 - x)) {
                ctx.fillRect(x, y, 1, 1);
              }
            }
          }
          charwrap = $('<li>');
          charwrap.data('char', c);
          charwrap.data('pos', j);
          charwrap.append(char);
          chars.append(charwrap);
        }
        set.append(chars);
        $('#sets').append(set);
      }
      $('#next-set').click(function(e) {
        _this.set++;
        if (_this.set > 14) {
          _this.set = 0;
        }
        return _this.fadeSet();
      });
      $('#prev-set').click(function(e) {
        _this.set--;
        if (_this.set < 0) {
          _this.set = 14;
        }
        return _this.fadeSet();
      });
      $('#char-lock').click(function(e) {
        _this.locked = !_this.locked;
        return $(e.target).toggleClass('on');
      });
      $('#sets ul li').click(function(e) {
        _this.char = $(e.currentTarget).data('char');
        _this.charpos = $(e.currentTarget).data('pos');
        return _this.draw();
      });
      return this.draw();
    };

    CharacterSets.prototype.draw = function() {
      var set, sets;
      sets = $('#sets > li');
      sets.hide();
      set = sets.filter(':nth-child(' + (this.set + 1) + ')');
      set.show();
      set.find('li').removeClass('selected');
      return set.find('li:nth-child(' + (this.charpos + 1) + ')').addClass('selected');
    };

    CharacterSets.prototype.fadeSet = function() {
      var _this = this;
      return $('#sets > li:visible').fadeOut('fast', function() {
        $('#sets > li:nth-child(' + (_this.set + 1) + ')').fadeIn('fast');
        _this.char = _this.sets[_this.set][_this.charpos];
        return _this.draw();
      });
    };

    return CharacterSets;

  })();

  Palette = (function() {

    function Palette(options) {
      var k, v;
      this.fg = 7;
      this.bg = 0;
      for (k in options) {
        if (!__hasProp.call(options, k)) continue;
        v = options[k];
        this[k] = v;
      }
    }

    Palette.prototype.init = function(editor) {
      var block, i, indicators, _i, _ref,
        _this = this;
      indicators = $('#fg,#bg');
      indicators.click(function(e) {
        if (!$(e.target).hasClass('selected')) {
          return indicators.toggleClass('selected', 200);
        }
      });
      $('#colors').children().empty();
      $('#colors').append('<ul class=first></ul>', '<ul></ul>');
      for (i = _i = 0, _ref = editor.image.palette.colors.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        block = $('<li>');
        block.data('color', i);
        block.css('background', this.toRgbaString(editor.image.palette.colors[i]));
        block.click(function(e) {
          _this[indicators.filter('.selected').attr('id')] = $(e.target).data('color');
          return _this.draw();
        });
        block.bind("contextmenu", function(e) {
          _this[indicators.filter('#bg').attr('id')] = $(e.target).data('color');
          _this.draw();
          return false;
        });
        $('#colors ul:nth-child(' + (1 + Math.round(i / (editor.image.palette.colors.length - 1))) + ')').append(block);
      }
      return this.draw();
    };

    Palette.prototype.draw = function() {
      $('#fg').css('background-color', this.toRgbaString(editor.image.palette.colors[this.fg]));
      $('#fg').css('color', this.toRgbaString(editor.image.palette.colors[this.fg > 8 ? 0 : 15]));
      $('#bg').css('background-color', this.toRgbaString(editor.image.palette.colors[this.bg]));
      $('#bg').css('color', this.toRgbaString(editor.image.palette.colors[this.bg > 8 ? 0 : 15]));
      return true;
    };

    Palette.prototype.toRgbaString = function(color) {
      return 'rgba(' + color.join(',') + ',1)';
    };

    return Palette;

  })();

  FileSelectHandler = function(e) {
    var file, files, _i, _len, _results;
    files = e.target.files || e.dataTransfer.files;
    _results = [];
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      _results.push(ParseFile(file));
    }
    return _results;
  };

  AbortParse = function() {
    return this.reader.abort();
  };

  ParseFile = function(file) {
    this.reader = new FileReader();
    $(this.reader).load(function(e) {
      var content, progress, progressIntervalID, start;
      progress = $(".percent");
      progress.width('100%');
      progress.text('100%');
      setTimeout("document.getElementById('progress_bar').className='';", 2000);
      editor.height = 0;
      content = e.target.result;
      start = new Date().getTime();
      console.log('Begin parsing');
      progressIntervalID = setInterval(function() {
        var end;
        end = new Date().getTime();
        return console.log((end - start) + 's');
      }, 1000);
      editor.image.parse(content);
      clearInterval(progressIntervalID);
      console.log('End parsing');
      editor.setHeight(editor.image.getHeight() * editor.image.font.height, false);
      editor.draw();
      editor.toggleLoadDialog();
      return true;
    });
    $(this.reader).error(function(e) {
      switch (e.target.error.code) {
        case e.target.error.NOT_FOUND_ERR:
          return alert("File Not Found!");
        case evt.target.error.NOT_READABLE_ERR:
          return alert("File is not readable");
        case evt.target.error.ABORT_ERR:
          break;
        default:
          return alert("An error occurred reading this file.");
      }
    });
    $(this.reader).bind("progress", function(e) {
      var percentLoaded;
      if (e.lengthComputable) {
        percentLoaded = Math.round((e.loaded / e.total) * 100);
        if (percentLoaded < 100) {
          progress.style.width = percentLoaded + "%";
          return progress.textContent = percentLoaded + "%";
        }
      }
    });
    $(this.reader).bind("abort", function(e) {
      return alert('File read cancelled');
    });
    $(this.reader).bind("loadstart", function(e) {
      $("#progress_bar").addClass("loading");
      return console.log("load started");
    });
    editor.setName(file.name);
    this.reader.readAsBinaryString(file);
    return false;
  };

  $(document).ready(function() {
    var fileselect;
    editor.init();
    editor.toggleHelpDialog();
    $('#splash .close').click(function() {
      editor.toggleHelpDialog();
      return false;
    });
    $('#drawings .close').click(function() {
      editor.toggleLoadDialog();
      return false;
    });
    $('#SaveDialog .close').click(function() {
      editor.toggleSaveDialog();
      return false;
    });
    if (window.File && window.FileList && window.FileReader) {
      fileselect = $("#fileselect");
      fileselect.change(function(e) {
        return FileSelectHandler(e);
      });
      return false;
    }
  });

  editor = new Editor;

}).call(this);
(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['editor'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, foundHelper, functionType="function", escapeExpression=this.escapeExpression;


  buffer += "<div id=\"splash\">\n    <a class=\"close\" href=\"#\"ß>&times;</a>\n    <h1>";
  foundHelper = helpers.title;
  if (foundHelper) { stack1 = foundHelper.call(depth0, {hash:{}}); }
  else { stack1 = depth0.title; stack1 = typeof stack1 === functionType ? stack1() : stack1; }
  buffer += escapeExpression(stack1) + "</h1>\n    ";
  foundHelper = helpers.help_header;
  if (foundHelper) { stack1 = foundHelper.call(depth0, {hash:{}}); }
  else { stack1 = depth0.help_header; stack1 = typeof stack1 === functionType ? stack1() : stack1; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    <h2>Colors</h2>\n    <dl>\n        <dt>ctrl + up/ctrl + down</dt>\n        <dd>Change foreground color</dd>\n        <dt>ctrl + left/ctrl + right</dt>\n        <dd>Change background color</dd>\n    </dl>\n    <h2>Characters</h2>\n    <dl>\n        <dt>alt + [f1..f10]</dt>\n        <dd>Switch extended character set</dd>\n        <dt>[f1..f10]</dt>\n        <dd>Place extended character</dd>\n    </dl>\n    ";
  foundHelper = helpers.help_footer;
  if (foundHelper) { stack1 = foundHelper.call(depth0, {hash:{}}); }
  else { stack1 = depth0.help_footer; stack1 = typeof stack1 === functionType ? stack1() : stack1; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n</div>\n<div id=\"drawings\">\n    <div id=\"html5Files\">\n        <a class=close href=#>&times;</a>\n        <h2>Your Drawings</h2>\n        <p class=\"alert\"><strong>Warning:</strong> clearing your cache will empty this list</p>\n        <ol></ol>\n    </div>\n    <div>\n        <h2>Upload Drawing</h2>\n        <form id=\"upload\" method=\"post\" enctype=\"multipart/form-data\">\n            <input type=\"hidden\" id=\"MAX_FILE_SIZE\" name=\"MAX_FILE_SIZE\" value=\"300000\" />\n            <div>\n                <label for=\"fileselect\">Drawing to upload: </label>\n                <input type=\"file\" id=\"fileselect\" name=\"fileselect\" />\n                <button onclick=\"abortRead();\">Cancel read</button>\n                <div id=\"progress_bar\"><div class=\"percent\">0%</div></div>\n            </div>\n        </form>\n    </div>\n    <div>\n        <h2>Dropbox Drawings</h2>\n        <a class=\"dropbox-login\" href=\"#\">Login to Dropbox</a>\n        <ol id=\"DropboxFiles\"></ol>\n    </div>\n</div>\n<div id=\"SaveDialog\">\n    <a class=close href=#>&times;</a>\n    <h2>Save</h2>\n    <label for=\"name\">Name (Optional)</label> <input id=name type=\"text\" />\n    <ul>\n        <li><a href=\"#\" id=\"PNGSave\">Save as PNG</a></li>\n        <li><a href=\"#\" id=\"html5Save\">Save to Browser</a></li>\n        <li id=\"DropboxContainer\">\n            <span id=\"DropboxSaveContainer\"><a href=\"#\" id=\"DropboxSave\">Save to Dropbox</a> as <span id=\"user-name\" /></span>\n            <a href=\"#\" class=\"dropbox-login\">Login to Dropbox</a>\n        </li>\n    </ul>\n</div>\n<div id=\"ErrorDialog\" class=\"dialog\">\n    <a class=\"close\" href=\"#\">&times;</a>\n    <h2>Error</h2>\n    <p class=\"message\" />\n</div>\n<div id=\"toolbar\">\n    <ul id=\"menu\">\n        <li id=\"save\">Save</li>\n        <li id=\"load\">Load</li>\n        <li id=\"clear\">Clear</li>\n    </ul>\n    <div id=\"cursorpos\">(1, 1)</div>\n    <div id=\"palette\">\n        <div id=fg class=selected>FG</div>\n        <div id=\"bg\">BG</div>\n        <div id=\"colors\"></div>\n        <div style=\"clear:both\"></div>\n    </div>\n    <div id=\"charsets\">\n        <ul id=\"sets\"></ul>\n        <div id=\"prev-set\">&#9668;</div>\n        <div id=\"next-set\">&#9658;</div>\n        <div id=\"char-lock\">Lock</div>\n    </div>\n</div>\n<div id=\"canvaswrapper\">\n    <div id=\"canvasscroller\">\n        <div id=\"highlight\" class=\"highlight\"></div>\n        <div id=\"cursor\"></div>\n        <canvas id=\"canvas\"></canvas>\n    </div>\n    <div id=\"vgawrapper\">\n        <div id=\"vgahighlight\" class=\"highlight\"></div>\n        <canvas id=\"vga\"></canvas>\n    </div>\n</div>";
  return buffer;});
})();
