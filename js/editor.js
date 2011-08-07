(function() {
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  this.Editor = (function() {
    this.Cursor = (function(){

      function Cursor() { };
      Object.defineProperties(this, {
        "x": { writable: true },
        "y": { writable: true },
        "width": { writable: true },
        "height": { writable: true }
      });
      return Cursor;
    });
    function Editor(w, h, id) {
      this.width = w;
      this.height = h;
      this.canvas = document.getElementById(id);
      this.canvas.setAttribute('width', this.width);
      this.canvas.setAttribute('height', this.height);

      this.cursor = new Cursor();
      this.cursor.width = 8;
      this.cursor.height = 16;
      this.cursor.x = 0;
      this.cursor.y = 0;

      if (this.canvas.getContext) {
        this.ctx = this.canvas.getContext('2d');
        //ctx.scale(.5,.5);
      }
      setInterval("editor.draw()", 300);

    $('body').bind('keydown', function(e) {
      key = {left:37, up:38, right:39, down:40, f1:112, f2:113, f3:114, f4:115, f5:116, f6:117, f7:118, f8:119, f9:120, f10:121, f11:122, f12:123};
      switch (e.which) {
        case key.left:
          if (editor.cursor.x > editor.cursor.width) {
            //eraseeditor.cursor(editor.cursor.x, editor.cursor.top);
            editor.cursor.x = editor.cursor.x - editor.cursor.width;
          }
          break;
        case key.right:
          if (editor.cursor.x < editor.width) {
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);         
            editor.cursor.x = editor.cursor.x + editor.cursor.width;
          }
          break;
        case key.down:
          if (editor.cursor.y < editor.height - editor.cursor.height) { // For now act on a fixed size canvas
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
            editor.cursor.y = editor.cursor.y + editor.cursor.height;
          }
          break;
        case key.up:
          if (editor.cursor.y > editor.cursor.height) {
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
            editor.cursor.y = editor.cursor.y - editor.cursor.height ;
          }
          break;
        case key.f5:
          alert("f5!");
          break;
      }
    });

    };
    Editor.prototype.draw = function() {
      this.ctx.fillStyle = "#ababab";
      this.ctx.fillRect(this.cursor.x,this.cursor.y,this.cursor.width,this.cursor.height);
      this.ctx.fill();
      return true;
    };


    return Editor;
  })();
}).call(this);