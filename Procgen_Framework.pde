import java.util.ArrayDeque;

int cellSize = 24;

PImage Tileset;

smartGrid testGrid;

void setup(){
  noStroke();
  size(1280,960,P2D);
  Tileset = loadImage("Tileset.png");
  for(int i = 0; i < height/cellSize; i++)
  for(int j = 0; j < width/cellSize; j++){
    
    rect(j*cellSize,i*cellSize,cellSize,cellSize);
  }
  testSection();

}

void testSection(){
  testGrid = new smartGrid(width/cellSize,height/cellSize);
  testGrid.generateMap();
  testGrid.display();
}
  


  
int currentMousex = 1;
int currentMousey = 1;





void draw(){
  
  stroke(#0000FF);
  fill(#000000);
  for(int i = 1; i < height/cellSize; i++)
  for(int j = 1; j < width/cellSize; j++){
    
    rect(j*cellSize,i*cellSize,cellSize,cellSize);
  }
  testGrid.display();
}

void keyPressed(){
  if(key == ' ')
    println("Breakpoint"); //<>//
  if(key == 'a')
    testSection();
}
