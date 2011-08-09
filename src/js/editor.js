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
    this.Block = (function(){
      function Block(char, attr) {
        this.char = char;
        this.attr = attr;
      }
      return Block;
    })();
    this.Cursor = (function(){

      function Cursor(w, h) {
        this.width = w;
        this.height = h;
        this.x = 0;
        this.y = 0;
        this.dom = $("#cursor");
        this.dom.width(this.width);
        this.dom.height(this.height);
        this.draw();
      };
      Cursor.prototype.draw = function() {
        this.dom.animate({left: (this.x + 1)*this.width}, 10);
        this.dom.animate({top: (this.y + 1)*this.height}, 10);
        return true;
      };
      Cursor.prototype.moveRight = function() {
        if (editor.cursor.x < editor.width/editor.cursor.width - 1) { // if within the bounds of the editor, move right
          editor.cursor.x++;
        } else if (editor.cursor.y < editor.height/editor.cursor.height - 1) { // if outside the bounds of the editor, and not on the last row, move the cursor down one row and to the first column
          editor.cursor.x = 0;
          editor.cursor.y++;
        }
        editor.cursor.draw();
      };   
      Cursor.prototype.moveLeft = function() {
        
        if (editor.cursor.x > 0) { // if within the bounds of the editor, move left
          editor.cursor.x--;          
        } else if (editor.cursor.y > 0) { // if outside the bounds of the editor, and not on the top row, move up one row and to the last column
          editor.cursor.y--
          editor.cursor.x = editor.width/editor.cursor.width - 1;
        }
        editor.cursor.draw();
      };      
      return Cursor;
    })();
    function Editor(w, h, id) {
      this.canvas = document.getElementById(id);
      this.canvas.style.cursor = "url('data:image/cur;base64,AAACAAEAICAAAAAAAAAwAQAAFgAAACgAAAAgAAAAQAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8%3D'), auto";
      this.canvas.setAttribute('width', this.width);
      this.canvas.setAttribute('height', this.height);

      this.width = this.canvas.clientWidth;
      this.height = this.canvas.clientHeight;

      this.cursor = new Cursor(8, 16);
      this.grid = new Array();
      // initialize block grid
      // for each column
      for (i = 0; i < this.width/this.cursor.width; i++) {
        var row = new Array();
        //for each row in column
        for (j = 0; j < this.height/this.cursor.height; j++) {
          row.push(new Block(' ', 0));
        }
        this.grid.push(row);
      }

      if (this.canvas.getContext) {
        this.ctx = this.canvas.getContext('2d');
        //ctx.scale(.5,.5);
      }
      setInterval("editor.draw()", 10);
      //this.draw();

      $('body').bind('keydown', function(e) {
        key = {left:37, up:38, right:39, down:40, f1:112, f2:113, f3:114, f4:115, f5:116, f6:117, f7:118, f8:119, f9:120, f10:121, f11:122, f12:123};
        //if (e.which >= 48 && e.which < )
        console.log("keydown: " + e.which);
        switch (e.which) {
          case key.left:
            editor.cursor.moveLeft();
            break;
          case key.right:
            editor.cursor.moveRight();
            break;
          case key.down:
            if (editor.cursor.y < (editor.height - editor.cursor.height)/editor.cursor.height) { // For now act on a fixed size canvas
              //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
              editor.cursor.y++;
              editor.cursor.draw();
            }
            break;
          case key.up:
            if (editor.cursor.y > 0) {
              //eraseeditor.cursor(editor.cursor.left, editor.cursor.top);
              editor.cursor.y--;
              editor.cursor.draw();
            }
            break;
          default:
            //console.log(e.which);
            break;
        }
      });
      $('body').bind('keypress', function(e) {
        var letter = String.fromCharCode(e.which);
        console.log("keypress: " + e.which + "/" + letter);
        var block = new Block(letter, 0);
        editor.grid[editor.cursor.x][editor.cursor.y] = block;
        editor.cursor.moveRight();
      });
    };
    Editor.prototype.draw = function() {
      this.ctx.fillStyle = "#000000";
      this.ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      this.ctx.fillStyle = "#ababab";
      for (var x = 0; x < this.grid.length;x++) {
        for (var y = 0; y < this.grid[x].length;y++) {
          if (this.grid[x][y].char != ' ')
            this.ctx.fillRect(x*this.cursor.width,y*this.cursor.height,this.cursor.width, this.cursor.height);
        }
      }
      this.ctx.fill();
      return true;
    };


    return Editor;
  })();
}).call(this);
