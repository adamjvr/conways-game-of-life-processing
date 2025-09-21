/**
 * Conway's Game of Life — Heatmap Age Visualization with Legend
 * ------------------------------------------------------------
 * Fix: size(...) must be called in settings() when using variables/expressions
 * or when certain renderers are involved. Calling size() in setup() sometimes
 * triggers the "size() cannot be used here" error. Putting size() into
 * settings() avoids that and is the recommended approach.
 *
 * This sketch:
 *  - Uses a Grid of Cells implementing Conway's rules (with wrap-around edges)
 *  - Tracks cell age (how many consecutive generations a cell has been alive)
 *  - Maps age to a heatmap color (blue→cyan→green→yellow→red)
 *  - Draws a legend on the right showing the age→color mapping
 *  - Supports a "trails" mode: when trails are enabled, the screen is not
 *    cleared every frame, leaving faded traces of previous generations.
 *
 * Important: size(...) is now in settings() — that's the fix for the error you saw.
 */

// ---------------------------
// CONFIG / GLOBALS
// ---------------------------

// Grid dimensions in cells (these are constant here; you may compute them before settings())
int cols = 80;      // number of columns (cells horizontally)
int rows = 60;      // number of rows (cells vertically)
int cellSize = 10;  // cell pixel size (width & height)

// Space reserved on the right for the legend (in pixels)
int legendReserved = 200;

// Color used as the background (also used to "clear" cells when trails are off)
color bgColor = color(30, 30, 30); // dark background so colored cells stand out

// How old should we consider "max" for color mapping (visual cap)
int maxAgeForColor = 50;

// Simulation objects
Grid grid;
Visualizer visualizer;

// Trails toggle: if true, previous frames partially persist (no full screen clear)
boolean trails = false;

// ---------------------------
// settings()
// ---------------------------
// In Processing, size(...) must be called from either settings() or setup().
// When size() is computed using variables (like cols, cellSize), put it in settings()
// to avoid the "size() cannot be used here" error.
void settings() {
  // Compute desired window width and height using the constants defined above.
  // We add 'legendReserved' space to the right so the grid does not overlap the legend.
  size(cols * cellSize + legendReserved, rows * cellSize);
}

// ---------------------------
// setup()
// ---------------------------
// Called once at start. Do runtime initialization here (not size()).
// ---------------------------
void setup() {
  // Construct simulation objects
  grid = new Grid(cols, rows);         // Prepare the cell grid
  visualizer = new Visualizer();       // Helper that draws grid + legend

  // Optional: Randomize initial grid population
  grid.randomize(0.25); // 25% initial alive probability (adjust to taste)

  // Frame rate controls how fast generations advance
  frameRate(12);

  // Set a sensible text size for the legend labels
  textSize(12);
}

// ---------------------------
// draw()
// ---------------------------
// Main loop: run once per frame
// ---------------------------
void draw() {
  // If trails are disabled, wipe the screen each frame with bgColor.
  // If trails are enabled, we intentionally DO NOT clear the screen so
  // colored cells leave a faded trail as they change over time.
  if (!trails) background(bgColor);

  // Step simulation:
  // 1) compute next states for all cells based on current generation
  // 2) apply those next states and update ages
  grid.computeNextStates();
  grid.updateStates();

  // Render the grid and legend
  visualizer.drawGrid(grid, cellSize);
  visualizer.drawLegend(cols * cellSize + 20, 40, 40, rows * cellSize - 80);
}


// ===================================================================
// CELL CLASS
// ===================================================================
/**
 * Represents a single cell in the Game of Life.
 * - alive: whether the cell is currently alive
 * - nextState: computed state for the next generation (so updates are synchronous)
 * - age: number of consecutive generations the cell has been alive
 */
class Cell {
  boolean alive;
  boolean nextState;
  int age;

  // Constructor: initialize as dead (you could randomize externally)
  Cell() {
    alive = false;
    nextState = false;
    age = 0;
  }

  // computeNextState(neighbors)
  // Apply Conway's rules using the supplied neighbor count.
  // Note: this only writes to nextState; it does not mutate 'alive' yet.
  void computeNextState(int neighbors) {
    if (alive) {
      // Live cell: survives only with 2 or 3 neighbors
      if (neighbors < 2 || neighbors > 3) nextState = false;
      else nextState = true;
    } else {
      // Dead cell: becomes alive only with exactly 3 neighbors
      nextState = (neighbors == 3);
    }
  }

  // updateState()
  // Commit nextState -> alive and update age accordingly.
  // Called after computeNextState() has been called for every cell.
  void updateState() {
    if (nextState) {
      if (alive) {
        // persisted alive: increment age
        age++;
      } else {
        // newly born: start age at 1
        age = 1;
      }
    } else {
      // will be dead: reset age
      age = 0;
    }
    // apply
    alive = nextState;
    // Optional: clamp age so color mapping doesn't overflow unexpectedly
    if (age > maxAgeForColor) age = maxAgeForColor;
  }

  // getHeatmapColor()
  // Convert the cell's age to a color on a heatmap scale:
  // blue -> cyan -> green -> yellow -> red as age increases.
  color getHeatmapColor() {
    // If the cell is dead, return the background color so it blends in.
    if (!alive) return bgColor;

    // Normalize age into 0..1 range based on maxAgeForColor.
    float norm = constrain((float)age / (float)maxAgeForColor, 0, 1);

    // We'll create a two-stage interpolation that gives more control
    // over the curve: first stage 0..0.5, second 0.5..1.0.
    // Stage 1 (young → mid): blue -> cyan -> green
    // Stage 2 (mid → old): green -> yellow -> red

    // Split norm into two halves
    float half = 0.5;
    if (norm <= half) {
      // When norm is in [0, 0.5], interpolate from blue -> cyan -> green
      // remap norm to 0..1 for this half
      float t = map(norm, 0, half, 0, 1);

      // First interpolate blue->cyan, then interpolate that -> green for smoother curve.
      // blue (0,0,255), cyan (0,255,255), green (0,255,0)
      color c1 = lerpColor(color(0, 0, 255), color(0, 255, 255), min(t * 2, 1)); // blue -> cyan
      color c2 = lerpColor(color(0, 255, 255), color(0, 255, 0), max(t * 2 - 1, 0)); // cyan -> green
      return lerpColor(c1, c2, t);
    } else {
      // When norm in (0.5, 1], interpolate from green -> yellow -> red
      // remap norm to 0..1 for this half
      float t = map(norm, half, 1, 0, 1);

      // green (0,255,0), yellow (255,255,0), red (255,0,0)
      color c1 = lerpColor(color(0, 255, 0), color(255, 255, 0), min(t * 2, 1)); // green -> yellow
      color c2 = lerpColor(color(255, 255, 0), color(255, 0, 0), max(t * 2 - 1, 0)); // yellow -> red
      return lerpColor(c1, c2, t);
    }
  }

  // displayAt(xPx, yPx, sizePx)
  // Draw the cell as a rectangle at pixel position (xPx, yPx).
  void displayAt(int xPx, int yPx, int sizePx) {
    // Choose fill color based on age/heatmap. If the cell is dead, fill with bgColor.
    fill(getHeatmapColor());
    noStroke();
    rect(xPx, yPx, sizePx, sizePx);
  }
}


// ===================================================================
// GRID CLASS
// ===================================================================
/**
 * Grid holds the 2D array of Cell objects and manages neighbor counting,
 * computing next states, and committing updates.
 *
 * This implementation uses wrap-around (toroidal) edges. If you prefer
 * non-wrap (out-of-bounds neighbors treated as dead), swap the modulo
 * arithmetic for bounds checks.
 */
class Grid {
  Cell[][] cells; // cells[col][row] indexing

  // Constructor: create and allocate the 2D cell array
  Grid(int cols, int rows) {
    cells = new Cell[cols][rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        cells[i][j] = new Cell();
      }
    }
  }

  // randomize(probAlive)
  // Set each cell alive with probability probAlive (0..1).
  // Initializes age accordingly.
  void randomize(float probAlive) {
    for (int i = 0; i < cells.length; i++) {
      for (int j = 0; j < cells[0].length; j++) {
        boolean a = random(1) < probAlive;
        cells[i][j].alive = a;
        cells[i][j].nextState = a;
        cells[i][j].age = a ? 1 : 0;
      }
    }
  }

  // countNeighbors(x, y)
  // Return number of alive neighbors for cell at (x, y).
  // Wraps at edges using modulo so the world is toroidal.
  int countNeighbors(int x, int y) {
    int count = 0;
    int C = cells.length;
    int R = cells[0].length;

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue; // skip self
        int nx = (x + dx + C) % C;
        int ny = (y + dy + R) % R;
        if (cells[nx][ny].alive) count++;
      }
    }
    return count;
  }

  // computeNextStates()
  // For every cell, compute nextState based on current neighbors.
  void computeNextStates() {
    int C = cells.length;
    int R = cells[0].length;
    for (int i = 0; i < C; i++) {
      for (int j = 0; j < R; j++) {
        int neighbors = countNeighbors(i, j);
        cells[i][j].computeNextState(neighbors);
      }
    }
  }

  // updateStates()
  // Commit nextState -> alive and update ages for all cells.
  void updateStates() {
    int C = cells.length;
    int R = cells[0].length;
    for (int i = 0; i < C; i++) {
      for (int j = 0; j < R; j++) {
        cells[i][j].updateState();
      }
    }
  }
}


// ===================================================================
// VISUALIZER CLASS
// ===================================================================
/**
 * Visualizer draws the grid of cells and the legend.
 * The legend shows the heatmap from young→old ages using the same color function.
 */
class Visualizer {

  // drawGrid(grid, sizePx)
  // Renders every cell as a rectangle in the main canvas area.
  void drawGrid(Grid g, int sizePx) {
    int C = g.cells.length;
    int R = g.cells[0].length;
    for (int i = 0; i < C; i++) {
      for (int j = 0; j < R; j++) {
        int xPx = i * sizePx;
        int yPx = j * sizePx;
        // When trails are enabled, we intentionally do not draw dead cells
        // as bg-colored tiles so the previous alive colors fade out gradually.
        if (g.cells[i][j].alive) {
          g.cells[i][j].displayAt(xPx, yPx, sizePx);
        } else {
          // If trails are disabled we must overwrite with background color
          if (!trails) {
            fill(bgColor);
            noStroke();
            rect(xPx, yPx, sizePx, sizePx);
          }
          // If trails are enabled, do not paint dead cells so earlier colors persist.
        }
      }
    }
  }

  // drawLegend(x, y, w, h)
  // Draw a vertical legend composed of many thin rectangles/lines,
  // mapping ages 1..maxAgeForColor to their corresponding heatmap color.
  void drawLegend(int x, int y, int w, int h) {
    // Background for legend area (slightly brighter than canvas bg)
    fill(50);
    noStroke();
    rect(x - 8, y - 8, w + 16, h + 16, 6); // rounded border background

    // Draw gradient: we'll iterate the pixel height and map each step to an age.
    for (int i = 0; i < h; i++) {
      // Map vertical position (0..h) to age (1..maxAgeForColor)
      float fract = map(i, 0, h - 1, 0, 1);
      int ageForStep = int(1 + fract * (maxAgeForColor - 1));
      // Create a temporary cell to use its heatmap function (or compute color inline)
      Cell tmp = new Cell();
      tmp.alive = true;
      tmp.age = ageForStep;
      color c = tmp.getHeatmapColor();
      stroke(c);
      line(x, y + i, x + w, y + i); // draw a 1px horizontal line across the legend width
    }

    // Draw outline around legend
    noFill();
    stroke(200);
    rect(x - 8, y - 8, w + 16, h + 16, 6);

    // Draw labels (top-to-bottom)
    fill(230);
    noStroke();
    textAlign(LEFT, CENTER);

    // Title
    textSize(14);
    text("Age Heatmap", x + w + 12, y - 8);

    // Numeric ticks: top (young), mid, bottom (old)
    textSize(12);
    textAlign(LEFT, CENTER);
    text("1", x + w + 12, y + 0);                 // very young
    text(str(maxAgeForColor/2), x + w + 12, y + h/2); // mid-age tick
    text(str(maxAgeForColor), x + w + 12, y + h - 1); // max-age (old)
  }
}

// ===================================================================
// OPTIONAL: Keyboard Interaction (toggle trails)
// ===================================================================
void keyPressed() {
  if (key == 't' || key == 'T') {
    trails = !trails;
  }
}
