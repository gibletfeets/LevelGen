enum sectionType {
  BRANCH, LEAF_FULL, LEAF_CUT;
}

void drawSprite(float x, float y, float w, float h, float tx, float ty, PImage currentTexture) {
  noStroke();
  //shader(cutoff);

  beginShape();
  texture(currentTexture);
  vertex(x, y, tx, ty);
  vertex(x+w, y, tx+w, ty);
  vertex(x+w, y+h, tx+w, ty+h);
  vertex(x, y+h, tx, ty+h);
  endShape();
  //resetShader();
}

class gridTile {
  int x; 
  int y;
  int index;

  gridTile(int _x, int _y) {
    x = _x; 
    y = _y;
  }

  void render() {
    drawSprite(cellSize*x, cellSize*y, 
      cellSize, cellSize, 
      cellSize*(index%4), cellSize*(index/4), Tileset);
    if ((index&8) != 8)
      drawSprite(cellSize*x, cellSize*(y+1), 
        cellSize, cellSize, 
        0, cellSize*4, Tileset);
  }
}

class smartGrid {
  int w; 
  int h;
  ArrayList<Section> Leaves = new ArrayList<Section>();
  gridTile[][] map;
  Node[] Nodes;
  Section rootSection;
  smartGrid(int _w, int _h) {
    w = _w; 
    h = _h;
    map = new gridTile[w][h];
  }
  boolean determineAdjacency(int x1, int y1, int w1, int h1, int x2, int y2, int w2, int h2){
  if (x1 + w1 >= x2 - 1 &&    // r1 right edge past r2 left
      x1 - 1 <= x2 + w2 &&    // r1 left edge past r2 right
      y1 + h1 >= y2 + 1 &&    // r1 top edge past r2 bottom
      y1 + 1 <= y2 + h2 ||
      x1 + w1 >= x2 + 1 &&    // r1 right edge past r2 left
      x1 + 1 <= x2 + w2 &&    // r1 left edge past r2 right
      y1 + h1 + 1 >= y2 - 2 &&    // r1 top edge past r2 bottom
      y1 - 2 <= y2 + h2 + 1) {    // r1 bottom edge past r2 top
        return true;
  }
  return false;
}
  void removeWall(Node _A, Node _B) { //this shit is sort of a mess and I just sorta made things work with it okay
    if (_A.Child.x == _B.Child.x+_B.Child.w) {
      int lower; 
      int upper;
      lower = max(_A.Child.y+1, _B.Child.y+1);
      upper = min(_A.Child.y+_A.Child.h-2, _B.Child.y+_B.Child.h-2);
      int index = round(random(lower, upper));
      map[_A.Child.x][index] = null;
      map[_A.Child.x][index+1] = null;
    }
    if (_A.Child.x+_A.Child.w == _B.Child.x) {
      int lower; 
      int upper;
      lower = max(_A.Child.y+1, _B.Child.y+1);
      upper = min(_A.Child.y+_A.Child.h-2, _B.Child.y+_B.Child.h-2);
      int index = round(random(lower, upper));
      map[_A.Child.x+_A.Child.w][index] = null;
      map[_A.Child.x+_A.Child.w][index+1] = null;
    }
    if (_A.Child.y == _B.Child.y+_B.Child.h) {
      int lower; 
      int upper;
      lower = max(_A.Child.x+1, _B.Child.x+1);
      upper = min(_A.Child.x+_A.Child.w-1, _B.Child.x+_B.Child.w-1);
      int index = round(random(lower, upper));
      map[index][_A.Child.y] = null;
      map[index][_A.Child.y+1] = null;
    }
    if (_A.Child.y+_A.Child.h == _B.Child.y) {
      int lower; 
      int upper;
      lower = max(_A.Child.x+1, _B.Child.x+1);
      upper = min(_A.Child.x+_A.Child.w-1, _B.Child.x+_B.Child.w-1);
      int index = round(random(lower, upper));
      map[index][_A.Child.y+_A.Child.h] = null;
      map[index][_A.Child.y+_A.Child.h+1] = null;
    }
  }
  void generateMap() {
    rootSection = new Section(0, 0, w-1, h-1);
    vomitMap(rootSection);
    invertBlocks();
    setNeighbors(rootSection);
    recursiveBacktrack(); //<>//
    determineIndices(); //<>//
  }

  void recursiveBacktrack() {
    int visited = 1;
    Node currentNode = Nodes[0];
    ArrayDeque<Node> stack = new ArrayDeque();
    ArrayList<Node> unvisited = new ArrayList<Node>();
    for (int i = 1; i < Nodes.length; i++) {
      if (currentNode.Child.x < Nodes[i].Child.x || currentNode.Child.y < Nodes[i].Child.y)
        currentNode = Nodes[i];
    }
    currentNode.visited = true;
    while (visited < Nodes.length) {

      for (int i = 0; i < currentNode.neighbors.size(); i++) {
        if (!currentNode.neighbors.get(i).visited)
          unvisited.add(currentNode.neighbors.get(i));
      }
      //println(unvisited.size());
      //println(stack.isEmpty());
      if (unvisited.size() > 0) {
        Node nextNode;
        stack.push(currentNode);
        int index = round(random(unvisited.size() - 1));
        nextNode = unvisited.get(index);
        nextNode.links[nextNode.neighbors.indexOf(currentNode)] = true;
        currentNode.links[currentNode.neighbors.indexOf(nextNode)] = true;
        removeWall(currentNode, nextNode);
        currentNode = unvisited.get(index);
        currentNode.visited = true;
        visited++;
        unvisited.clear();
      } else if (!stack.isEmpty()) {
        currentNode = stack.pop();
      }
      //println(visited + "/" + Nodes.length);
      if (stack.isEmpty() && unvisited.size() == 0)
        break;
    }
  }

  void setNeighbors(Section _input) {
    Leaves.clear();
    outputLeaves(_input);
    Nodes = new Node[Leaves.size()];
    for (int i = 0; i < Leaves.size(); i++) {
      Nodes[i] = new Node(Leaves.get(i));
    }
    for (int i = 0; i < Nodes.length-1; i++) {
      Node n1 = Nodes[i];
      for (int j = i+1; j < Nodes.length; j++) {
        Node n2 = Nodes[j];
        stroke(#00FF00);
        if (determineAdjacency(n1.Child.x+1, n1.Child.y+2, n1.Child.w-1, n1.Child.h-2, 
          n2.Child.x+1, n2.Child.y+2, n2.Child.w-1, n2.Child.h-1)) {
          n1.neighbors.add(n2);
          if (!n2.neighbors.contains(n1))
            n2.neighbors.add(n1);
          //n1.links[n1.neighbors.size()-1] = true;
        }
      }
    }
  }
  
  void displayGraph() {
    for (int i = 0; i < Nodes.length; i++)
      Nodes[i].Child.printInfo();

    for (int i = 0; i < Nodes.length; i++)
      for (int j = 0; j < Nodes[i].neighbors.size(); j++) {
        if (Nodes[i].links[j] == true) {
          line(cellSize*(Nodes[i].Child.x+1)+cellSize*(Nodes[i].Child.w-1)/2, 
            cellSize*(Nodes[i].Child.y+1)+cellSize*Nodes[i].Child.h/2, 
            cellSize*(Nodes[i].neighbors.get(j).Child.x+1)+cellSize*(Nodes[i].neighbors.get(j).Child.w-1)/2, 
            cellSize*(Nodes[i].neighbors.get(j).Child.y+1)+cellSize*Nodes[i].neighbors.get(j).Child.h/2);
        }
      }
  }
  
  gridTile getTile(int _x, int _y) {
    if (_x >= 0 && _x < w
      &&_y >= 0 && _y < h) {
      if (map[_x][_y] != null) return map[_x][_y];
    }
    return null;
  }
  
  void invertBlocks() {
    for (int i = 0; i < h; i++)
      for (int j = 0; j < w; j++) {
        if (map[j][i] != null) map[j][i] = null;
        else                   map[j][i] = new gridTile(j, i);
      }
  }
  
  void determineIndices() {
    for (int i = 0; i < h; i++)
      for (int j = 0; j < w; j++) {
        if (map[j][i] != null) {
          int acc = 0;
          acc += int(getTile(j, i-1) != null);
          acc += int(getTile(j-1, i) != null)*2;
          acc += int(getTile(j+1, i) != null)*4;
          acc += int(getTile(j, i+1) != null)*8;
          map[j][i].index = acc;
        }
      }
  }

  void addTile(int x, int y) {
    map[x][y] = new gridTile(x, y);
  }

  void display() {
    for (int i = 0; i < h; i++)
      for (int j = 0; j < w; j++)
        if (map[j][i] != null)
          map[j][i].render();
  }
  void tileRect(Section _S) {
    for (int i = 1; i < _S.h; i++)
      for (int j = 1; j < _S.w; j++) {
        addTile(_S.x+j, _S.y+i);
      }
  }

  void cutRect(Section _S) {
  }

  void vomitMap(Section _S) {
    switch(_S.thisType) {
    case LEAF_FULL:
      tileRect(_S);
      break;
    case LEAF_CUT:
      cutRect(_S);
      break;
    case BRANCH:
      for (int i = 0; i < _S.children.length; i++) {
        vomitMap(_S.children[i]);
      }
      break;
    }
  }
  void outputLeaves(Section _S) {
    if (_S.thisType == sectionType.BRANCH)
      for (int i = 0; i < _S.children.length; i++) //<>//
       outputLeaves(_S.children[i]); //<>//
    else {
      Leaves.add(_S);
    }
  }
}
class Node {
  ArrayList<Node> neighbors = new ArrayList<Node>(4);
  boolean[] links = new boolean[16];
  boolean visited = false;
  Section Child;
  Node(Section _input) {
    Child = _input;
    for (int i = 0; i < links.length; i++) {
      links[i] = false;
    }
  }
}
class Section {
  int x; 
  int y;
  int w; 
  int h;
  int w2; 
  int h2;
  sectionType thisType = sectionType.BRANCH;
  Section[] children;

  Section[] archetypes;
  Section(int _x, int _y, int _w, int _h) {
    x = _x; 
    y = _y;
    w = _w; 
    h = _h;
    generateChildren();
    if (children == null)
      if (random(1) > 0.0)
        thisType = sectionType.LEAF_FULL;
      else {
        w2 = max(3, w/2);
        h2 = max(3, h/2);
        thisType = sectionType.LEAF_CUT;
      }
  }
  void splitSelf() {
    children = new Section[2];
    if (w > h) {
      int randomB = min(round(random(3*float(w)/5, 4*float(w)/5)), w-5);
      children[0] = new Section(x, y, randomB, h);
      children[1] = new Section(x+randomB, y, w-randomB, h);
    } else {
      int randomB = min(round(random(3*float(h)/5, 4*float(h)/5)), h-5);
      children[0] = new Section(x, y, w, randomB);
      children[1] = new Section(x, y+randomB, w, h-randomB);
    }
  }
  void generateChildren() {
    if (w > 5 || h > 5) {
      if (max(float(w)/float(h), float(h)/float(w)) < 2.5) {
        IntList validDivisionsW = new IntList();
        IntList validDivisionsH = new IntList();
        for (int i = 2; i <= 10; i++) {
          if (w/i > 3 &&w%i == 0)
            validDivisionsW.append(i);
          if (h/i > 3 &&h%i == 0)
            validDivisionsH.append(i);
        }
        int divW = 1; 
        int divH = 1;
        if (validDivisionsW.size() > 0) {
          //println(validDivisionsW);
          validDivisionsW.shuffle();
          divW = validDivisionsW.get(0);
        }
        if (validDivisionsH.size() > 0) {
          //println(validDivisionsH);
          validDivisionsH.shuffle();
          divH = validDivisionsH.get(0);
        }
        if (divW == 1 || divH == 1) {
          if (w*h > 49)
            splitSelf(); 
          return;
        }
        //println("Divisions: " + divW + "," + divH);
        children = new Section[divW*divH];
        int newW = w/divW;
        int newH = h/divH;
        for (int i = 0; i < divH; i++)
          for (int j = 0; j < divW; j++) {
            children[j+divW*i] = new Section(x+j*(newW), y+i*(newH), newW, newH);
          }
      } else if (random(1.0) > 0.5)splitSelf();
    }
  }


  void printInfo() {
    stroke(#FF0000);
    fill(#000000);
    rect(cellSize*(x+1), cellSize*(y+2), cellSize*(w-1), cellSize*(h-2));
    stroke(#00FF00);
    ellipse(cellSize*(x) + cellSize*(w+1)/2, cellSize*(y) + cellSize*(h+2)/2, cellSize, cellSize);
    fill(#FF00FF);
    text("("+(x+1)+","+(y+2)+")", cellSize*(x+1)+6, cellSize*(y+2)+12);
    text("("+(w-1)+","+(h-2)+")", cellSize*(x+1)+6, cellSize*(y+3));
  }
}
