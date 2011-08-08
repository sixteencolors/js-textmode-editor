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
      Cursor.prototype.move = function() {
        dom.animate({left: x*width}, 10);
        dom.animate({top: y*height}, 10);
        return true;
      };
      Object.defineProperties(this, {
        "x": { writable: true },
        "y": { writable: true },
        "width": { writable: true },
        "height": { writable: true },
        "dom" : {writable: true}
      });
      return Cursor;
    });
    function Editor(w, h, id) {
      this.width = w;
      this.height = h;
      this.canvas = document.getElementById(id);
      this.canvas.style.cursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto";
      this.canvas.setAttribute('width', this.width);
      this.canvas.setAttribute('height', this.height);

      this.cursor = new Cursor();
      this.cursor.dom = $("#cursor");
      this.cursor.width = 8;
      this.cursor.height = 16;
      this.cursor.x = 1;
      this.cursor.y = 1;
      this.cursor.dom.width(this.cursor.width);
      this.cursor.dom.height(this.cursor.height);

      if (this.canvas.getContext) {
        this.ctx = this.canvas.getContext('2d');
        //ctx.scale(.5,.5);
      }
//      setInterval("editor.draw()", 9);

    $('body').bind('keydown', function(e) {
      key = {left:37, up:38, right:39, down:40, f1:112, f2:113, f3:114, f4:115, f5:116, f6:117, f7:118, f8:119, f9:120, f10:121, f11:122, f12:123};
      switch (e.which) {
        case key.left:
          if (editor.cursor.x > editor.cursor.width/editor.cursor.width) {
            //eraseeditor.cursor(editor.cursor.x, editor.cursor.top);
            editor.cursor.x--;
            editor.cursor.dom.animate({left: editor.cursor.x*editor.cursor.width}, 10)
          }
          break;
        case key.right:
          if (editor.cursor.x < editor.width/editor.cursor.width) {
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);         
            editor.cursor.x++;
            editor.cursor.move();
            //editor.cursor.dom.animate({left: (editor.cursor.x*editor.cursor.width)}, 10)
          }
          break;
        case key.down:
          if (editor.cursor.y < (editor.height - editor.cursor.height)/editor.cursor.height) { // For now act on a fixed size canvas
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
            editor.cursor.y++;
            editor.cursor.dom.animate({top: editor.cursor.y*editor.cursor.height}, 10)
          }
          break;
        case key.up:
          if (editor.cursor.y > 0) {
            //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
            editor.cursor.y--;
            editor.cursor.dom.animate({top: editor.cursor.y*editor.cursor.height}, 10)
          }
          break;
        case key.f5:
          alert("f5!");
          break;
      }
    });

    };
    Editor.prototype.draw = function() {
      this.ctx.fillStyle = "#000000";
      this.ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      this.ctx.fillStyle = "#ababab";
      this.ctx.fillRect(this.cursor.x*this.cursor.width,this.cursor.y*this.cursor.height,this.cursor.width,this.cursor.height);
      this.ctx.fill();
      return true;
    };


    return Editor;
  })();
}).call(this);
