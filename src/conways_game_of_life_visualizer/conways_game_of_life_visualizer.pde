// ============================================================================
// Conway's Game of Life with Resizable Window, Heatmap Coloring, and Legend
// ============================================================================
//
// Same as before, but restored to the original blue → green → red heatmap style
//
// ============================================================================

GameOfLife game;
Visualizer vis;
Legend legend;

int cellSize = 10;

void settings() {
  size(800, 600);
}

void setup() {
  surface.setResizable(true);

  int cols = width / cellSize;
  int rows = height / cellSize;
  
  game = new GameOfLife(cols, rows);
  vis = new Visualizer(cellSize);
  legend = new Legend(20, height - 120, 200, 100);
}

void draw() {
  background(255);

  int cols = width / cellSize;
  int rows = height / cellSize;
  game.resize(cols, rows);

  game.update();

  vis.display(game);

  legend.updatePosition(20, height - 120); 
  legend.display();
}

// ============================================================================
// Class: Cell
// ============================================================================
class Cell {
  boolean alive;
  int age;

  Cell() {
    alive = random(1) < 0.2;
    age = 0;
  }

  void updateState(boolean nextAlive) {
    if (nextAlive) {
      if (alive) {
        age++;
      } else {
        age = 1;
      }
    } else {
      age = 0;
    }
    alive = nextAlive;
  }
}

// ============================================================================
// Class: GameOfLife
// ============================================================================
class GameOfLife {
  Cell[][] grid;
  int cols, rows;

  GameOfLife(int cols, int rows) {
    this.cols = cols;
    this.rows = rows;
    grid = new Cell[cols][rows];
    initialize();
  }

  void initialize() {
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        grid[x][y] = new Cell();
      }
    }
  }

  void resize(int newCols, int newRows) {
    if (newCols == cols && newRows == rows) return;

    Cell[][] newGrid = new Cell[newCols][newRows];

    for (int x = 0; x < newCols; x++) {
      for (int y = 0; y < newRows; y++) {
        if (x < cols && y < rows) {
          newGrid[x][y] = grid[x][y];
        } else {
          newGrid[x][y] = new Cell();
        }
      }
    }

    grid = newGrid;
    cols = newCols;
    rows = newRows;
  }

  void update() {
    boolean[][] nextStates = new boolean[cols][rows];

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        int neighbors = countNeighbors(x, y);
        if (grid[x][y].alive) {
          nextStates[x][y] = (neighbors == 2 || neighbors == 3);
        } else {
          nextStates[x][y] = (neighbors == 3);
        }
      }
    }

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        grid[x][y].updateState(nextStates[x][y]);
      }
    }
  }

  int countNeighbors(int x, int y) {
    int sum = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = (x + dx + cols) % cols;
        int ny = (y + dy + rows) % rows;
        if (grid[nx][ny].alive) {
          sum++;
        }
      }
    }
    return sum;
  }
}

// ============================================================================
// Class: Visualizer
// ============================================================================
class Visualizer {
  int cellSize;

  Visualizer(int cellSize) {
    this.cellSize = cellSize;
  }

  void display(GameOfLife game) {
    for (int x = 0; x < game.cols; x++) {
      for (int y = 0; y < game.rows; y++) {
        Cell c = game.grid[x][y];
        if (c.alive) {
          color col = ageToColor(c.age);
          fill(col);
        } else {
          fill(0);
        }
        noStroke();
        rect(x * cellSize, y * cellSize, cellSize, cellSize);
      }
    }
  }

  color ageToColor(int age) {
    int maxAge = 50;
    float norm = constrain(map(age, 0, maxAge, 0, 1), 0, 1);

    if (norm < 0.5) {
      // First half of the scale: Blue → Green
      return lerpColor(color(0, 0, 255), color(0, 255, 0), norm * 2);
    } else {
      // Second half: Green → Red
      return lerpColor(color(0, 255, 0), color(255, 0, 0), (norm - 0.5) * 2);
    }
  }
}

// ============================================================================
// Class: Legend
// ============================================================================
class Legend {
  int x, y, w, h;

  Legend(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  void updatePosition(int newX, int newY) {
    x = newX;
    y = newY;
  }

  void display() {
    for (int i = 0; i < w; i++) {
      float norm = map(i, 0, w, 0, 1);
      color col;
      if (norm < 0.5) {
        col = lerpColor(color(0, 0, 255), color(0, 255, 0), norm * 2);
      } else {
        col = lerpColor(color(0, 255, 0), color(255, 0, 0), (norm - 0.5) * 2);
      }
      stroke(col);
      line(x + i, y, x + i, y + h);
    }

    noFill();
    stroke(0);
    rect(x, y, w, h);

    fill(0);
    textAlign(LEFT, TOP);
    text("Age →", x, y - 15);
    text("Young", x, y + h + 5);
    text("Old", x + w - 40, y + h + 5);
  }
}
