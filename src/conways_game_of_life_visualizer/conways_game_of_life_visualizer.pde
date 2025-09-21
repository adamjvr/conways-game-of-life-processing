// ============================================================================
// Conway's Game of Life with Resizable Window, Heatmap Coloring, and Legend
// ============================================================================

/*
 * This Processing sketch implements Conway's Game of Life with several 
 * enhancements to improve visualization and usability.
 *
 * Features:
 *  - A grid of cells that evolve according to Conway's rules
 *    (with wrap-around edges, meaning the grid "loops" like a torus).
 *  - Each cell tracks its "age" (how many generations it has been alive).
 *  - Age values are mapped to a heatmap color scale:
 *       Blue → Green → Red
 *    so that older cells appear visually distinct from younger ones.
 *  - A legend is drawn to the right side of the window showing the age→color
 *    mapping for easy reference.
 *  - The program supports a resizable window, meaning the grid will expand or
 *    shrink dynamically as the user drags the window edges.
 *
 * Technical Note:
 *  In Processing 3 and newer, `size()` must be called from within `settings()`
 *  instead of `setup()` if you want to support features like resizable windows.
 */

// ============================================================================
// Global Variables
// ============================================================================

// Object responsible for running the Game of Life logic
GameOfLife game;

// Object responsible for drawing the grid of cells
Visualizer vis;

// Object responsible for drawing the legend (color bar + labels)
Legend legend;

// The pixel size of each cell in the grid (controls grid resolution)
int cellSize = 10;


// ============================================================================
// Processing Lifecycle Methods
// ============================================================================

void settings() {
  // Define the initial canvas size in pixels
  // Width = 800px, Height = 600px
  // This is placed inside settings() instead of setup() for compatibility
  // with features like resizable windows.
  size(800, 600);
}

void setup() {
  // Allow the Processing sketch window to be resized by the user.
  surface.setResizable(true);

  // Compute how many columns and rows fit in the current canvas size.
  // For example, width=800 and cellSize=10 → cols=80.
  int cols = width / cellSize;
  int rows = height / cellSize;
  
  // Initialize the Game of Life with the calculated grid size
  game = new GameOfLife(cols, rows);

  // Initialize the Visualizer that will draw the cells
  vis = new Visualizer(cellSize);

  // Initialize the Legend with its starting position and dimensions.
  // Parameters: x=20, y=(bottom offset 120px), width=200, height=100
  legend = new Legend(20, height - 120, 200, 100);
}

void draw() {
  // Clear the background every frame with white (RGB 255,255,255).
  // If you wanted trails instead, you would omit this line.
  background(255);

  // Recalculate the number of rows and columns based on the *current* window size.
  // This allows dynamic resizing: if the user drags the window larger, the grid grows.
  int cols = width / cellSize;
  int rows = height / cellSize;

  // Resize the Game of Life grid if the window size changed
  game.resize(cols, rows);

  // Advance the Game of Life simulation by one generation
  game.update();

  // Draw the current state of the simulation (cells with heatmap coloring)
  vis.display(game);

  // Update the legend's vertical position so it always stays near the bottom.
  legend.updatePosition(20, height - 120);

  // Draw the legend (gradient color bar + labels)
  legend.display();
}


// ============================================================================
// Class: Cell
// ============================================================================
/*
 * Represents a single cell in the Game of Life grid.
 * Each cell knows:
 *  - Whether it is alive (boolean).
 *  - How many consecutive generations it has been alive (age counter).
 */
class Cell {
  boolean alive; // True if the cell is alive, false if dead
  int age;       // Age of the cell (only increments while alive)

  // Constructor: Randomly initializes cell state
  Cell() {
    // 20% chance (random < 0.2) that a cell starts alive
    alive = random(1) < 0.2;
    // Initially age = 0 (a newborn will age in the next update)
    age = 0;
  }

  // Updates the state of the cell for the next generation
  // nextAlive: whether this cell should be alive in the new generation
  void updateState(boolean nextAlive) {
    if (nextAlive) {
      // If the cell stays alive, increment age
      if (alive) {
        age++;
      } else {
        // If it was previously dead but now alive, reset age to 1
        age = 1;
      }
    } else {
      // Dead cells have age reset to 0
      age = 0;
    }
    // Commit the new alive/dead state
    alive = nextAlive;
  }
}


// ============================================================================
// Class: GameOfLife
// ============================================================================
/*
 * This class encapsulates the entire Game of Life simulation.
 * It manages a 2D array of cells and handles:
 *  - Initialization
 *  - Resizing when the window size changes
 *  - Updating cell states according to Conway's rules
 *  - Counting neighbors for each cell (with wrap-around edges)
 */
class GameOfLife {
  Cell[][] grid; // 2D array storing all cells
  int cols, rows; // Current number of columns and rows in the grid

  // Constructor: Create a grid of the given size and initialize it
  GameOfLife(int cols, int rows) {
    this.cols = cols;
    this.rows = rows;
    grid = new Cell[cols][rows];
    initialize();
  }

  // Fills the grid with newly created cells (random alive/dead states)
  void initialize() {
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        grid[x][y] = new Cell();
      }
    }
  }

  // Resizes the grid when the window changes dimensions
  void resize(int newCols, int newRows) {
    // Skip if size has not actually changed
    if (newCols == cols && newRows == rows) return;

    // Allocate a new grid of the requested size
    Cell[][] newGrid = new Cell[newCols][newRows];

    // Copy over existing cells where possible (within overlap region)
    for (int x = 0; x < newCols; x++) {
      for (int y = 0; y < newRows; y++) {
        if (x < cols && y < rows) {
          // Preserve existing cell state if within old grid
          newGrid[x][y] = grid[x][y];
        } else {
          // Initialize new cells if expanding beyond old dimensions
          newGrid[x][y] = new Cell();
        }
      }
    }

    // Replace old grid with resized one
    grid = newGrid;
    cols = newCols;
    rows = newRows;
  }

  // Advances the simulation by one step (generation)
  void update() {
    // First, calculate what each cell’s next state should be
    boolean[][] nextStates = new boolean[cols][rows];

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        int neighbors = countNeighbors(x, y);

        // Apply Conway's rules:
        // - Alive cell survives only with 2 or 3 neighbors
        // - Dead cell becomes alive if it has exactly 3 neighbors
        if (grid[x][y].alive) {
          nextStates[x][y] = (neighbors == 2 || neighbors == 3);
        } else {
          nextStates[x][y] = (neighbors == 3);
        }
      }
    }

    // Second, update each cell’s state using the computed results
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        grid[x][y].updateState(nextStates[x][y]);
      }
    }
  }

  // Counts how many neighbors of a given cell are alive
  // Uses wrap-around so that edges connect to the opposite side
  int countNeighbors(int x, int y) {
    int sum = 0;

    // Check all 8 surrounding cells
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        // Skip self (dx=0, dy=0)
        if (dx == 0 && dy == 0) continue;

        // Wrap-around (modulus ensures edges loop back around)
        int nx = (x + dx + cols) % cols;
        int ny = (y + dy + rows) % rows;

        // Add to count if neighbor is alive
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
/*
 * Responsible for drawing the Game of Life grid to the screen.
 * Each alive cell is drawn as a colored square.
 * Dead cells are drawn as black squares.
 * Color is determined by the age of the cell via a heatmap function.
 */
class Visualizer {
  int cellSize; // Pixel size of each cell

  Visualizer(int cellSize) {
    this.cellSize = cellSize;
  }

  // Render the current state of the game to the screen
  void display(GameOfLife game) {
    for (int x = 0; x < game.cols; x++) {
      for (int y = 0; y < game.rows; y++) {
        Cell c = game.grid[x][y];

        // If cell is alive, pick a color based on age
        if (c.alive) {
          color col = ageToColor(c.age);
          fill(col);
        } else {
          // Dead cells are black
          fill(0);
        }

        // Draw the cell as a rectangle (no borders)
        noStroke();
        rect(x * cellSize, y * cellSize, cellSize, cellSize);
      }
    }
  }

  // Converts a cell's age into a color
  // Young cells = blue, medium = green, old = red
  color ageToColor(int age) {
    int maxAge = 50; // After this age, color saturates
    float norm = constrain(map(age, 0, maxAge, 0, 1), 0, 1);

    if (norm < 0.5) {
      // First half of scale: interpolate from Blue (young) → Green (middle-aged)
      return lerpColor(color(0, 0, 255), color(0, 255, 0), norm * 2);
    } else {
      // Second half of scale: interpolate from Green → Red (old)
      return lerpColor(color(0, 255, 0), color(255, 0, 0), (norm - 0.5) * 2);
    }
  }
}


// ============================================================================
// Class: Legend
// ============================================================================
/*
 * Draws a reference legend that shows how cell age maps to color.
 * The legend is drawn as a horizontal gradient bar (blue→green→red),
 * with a labeled border and text indicating "Young" and "Old".
 */
class Legend {
  int x, y, w, h; // Position and size of legend box

  Legend(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  // Update the position of the legend dynamically (e.g., when window is resized)
  void updatePosition(int newX, int newY) {
    x = newX;
    y = newY;
  }

  // Draw the legend on screen
  void display() {
    // Draw the gradient bar, pixel by pixel across width
    for (int i = 0; i < w; i++) {
      float norm = map(i, 0, w, 0, 1);
      color col;

      if (norm < 0.5) {
        // Left half: interpolate from Blue → Green
        col = lerpColor(color(0, 0, 255), color(0, 255, 0), norm * 2);
      } else {
        // Right half: interpolate from Green → Red
        col = lerpColor(color(0, 255, 0), color(255, 0, 0), (norm - 0.5) * 2);
      }

      // Draw a vertical line for this slice of the gradient
      stroke(col);
      line(x + i, y, x + i, y + h);
    }

    // Draw a border around the gradient bar
    noFill();
    stroke(0);
    rect(x, y, w, h);

    // Draw labels above and below the legend
    fill(0);
    textAlign(LEFT, TOP);
    text("Age →", x, y - 15);
    text("Young", x, y + h + 5);
    text("Old", x + w - 40, y + h + 5);
  }
}
