import java.util.*;
import java.awt.event.KeyEvent;
import java.awt.event.KeyEvent.*;

int bg = color(126);
int WIDTH = 600; int HEIGHT = 300;
int BORDER = 1000000;
PFont font;

String state = "playing";
float score = 0;
boolean filters = true;
boolean OBSTACLE = true;
boolean DIST1 = true;
boolean SHAKEH = true;
boolean SHAKEV = SHAKEH;
boolean ROTATE = true;
boolean SCALEX = true;
boolean SCALEY = SCALEX;
boolean CIRCLE = false;
int playerSpawnX = 50;
int obstacleSpawnReset = 20;
int obstacleSpawnTimer = obstacleSpawnReset;
int distractionChance1 = 2;
int distractionMultiplier1 = 2;
int transformationChance1 = 20; // shakeH
int transformationMax1 = 4;
int transformationChance2 = 20; // shakeV
int transformationMax2 = 4;
int transformationChance3 = 20; // rotate
int transformationMax3 = 4;
int transformationChance4 = 20; // scaleX
int transformationMax4 = 4;
int transformationChance5 = 20; // scaleY
int transformationMax5 = 4;
int transformationChance6 = 500; // circle
int transformationMax6 = 1;
int shakeDistance = 36;
int rotateDistance = 36;
float scaleFactor = 0.15;

Player player;
ArrayList<RSprite> obstacles;
ArrayList<Sprite> distractions;
ArrayList<Transformation> transformations;

HashSet<Integer> keysDown = new HashSet<Integer>();

float clamp(float lower, float num, float upper) {
  return max(min(num, upper), lower);
}

int randint(int upper) {
  return int(random(upper));
}

boolean randbool() {
  return randint(2) == 0;
}

int transformationsOfType(String type) {
  int total = 0;
  for (Transformation transformation : transformations) {
    if (transformation.name == type) {
      total += 1;
    }
  }

  return total;
}

class Sprite {
  boolean clear;
  String name;
  Sprite () {
    clear = false;
    name = "unknown";
  }
  Sprite (String name_) {
    this();
    name = name_;
  }
  void draw() {
    println("[ERROR] Draw method not overridden in subclass.");
  }
  void anim() {
    println("[ERROR] Anim method not overridden in subclass.");
  }
}

class RSprite extends Sprite {
  float x, y, w, h;
  float vx, vy;
  int c, oc;
  String shape;
  RSprite () {
    super();
    shape = "rect";
  }
  RSprite (String name_) {
    super(name_);
    shape = "rect";
    if (name == "rcolorbox") {
      shape = "rect";
      w = randint(60) + 20;
      h = w;
      c = color(random(255), random(255), random(255), random(255));
      oc = c;
      switch (randint(4)) {
        case 0: {
          x = random(-w, WIDTH);
          y = -h;
          vx = random(3) + 1;
          if (randbool()) vx = -vx;
          vy = random(6) + 2;
          break;
        }
        case 1: {
          x = random(-w, WIDTH);
          y = HEIGHT;
          vx = random(3) + 1;
          if (randbool()) vx = -vx;
          vy = -random(6) - 2;
          break;
        }
        case 2: {
          x = -w;
          y = random(-h, HEIGHT);
          vx = random(6) + 2;
          vy = random(3) + 1;
          if (randbool()) vy = -vy;
          break;
        }
        case 3: {
          x = WIDTH;
          y = random(-h, HEIGHT);
          vx = -random(6) - 2;
          vy = random(3) + 1;
          if (randbool()) vy = -vy;
          break;
        }
      }
    }
  }
  void draw() {
    fill(c);
    stroke(oc);
    if (shape == "rect") {
      rect(x, y, x + w, y + h);
    }
    else if (shape == "ellipse") {
      ellipse(x, y, x + w, y + h);
    }
    else {
      println("[ERROR] RSprite shape not set.");
    }
  }
  void anim() {
    if (name == "rcolorbox") {
      x += vx;
      y += vy;
      clear = vx > 0 && x > WIDTH || vx < 0 && x < -w || vy > 0 && y > HEIGHT || vy < 0 && y < -h;
    }
  }
}

class Player extends RSprite {
  float vx, vy;
  Player () {
    super("player");
    w = 20;
    h = 20;
    c = color(220, 20, 60);
    oc = color(0);
    
    x = playerSpawnX;
    y = HEIGHT/2 - h/2;
    vx = 0;
    vy = 0;
  }
  void anim() {
    if (keyDown(UP) || keyDown(KeyEvent.VK_W)) {
      vy -= 0.6;
    }
    if (keyDown(DOWN) || keyDown(KeyEvent.VK_S)) {
      vy += 0.6;
    }
    vy *= 0.9;
    y += vy;
    y = clamp(0, y, HEIGHT - h - 1);
    if (y == 0) vy = 0;
    if (y == HEIGHT - h - 1) vy = 0;
  }
  boolean collide(RSprite object) {
    return !(object.x > x + w || object.x + object.w < x || object.y > y + h || object.y + object.h < y);
  }
}

class Obstacle extends RSprite {
  Obstacle () {
    super("obstacle");
    w = 30;
    h = 30;
    c = color(255, 0);
    oc = color(0);
    
    x = WIDTH + 1;
    y = random(-h, HEIGHT - 1);
  }
  void anim() {
    x -= 4;
    clear = x < -w;
  }
}

class Transformation {
  String name;
  boolean clear;
  float age;
  float totalage;
  float offset;
  float speed;
  int direction;
  int axis;
  Transformation (String name_) {
    clear = false;
    name = name_;
    direction = 1;
    if (name == "shakeH" || name == "shakeV") {
      totalage = shakeDistance * (randint(3) + 1);
      offset = 0;
      speed = randint(4) + 1;
      totalage /= speed;
      direction = randint(2)*2-1;
    }
    if (name == "rotate") {
      totalage = rotateDistance * (randint(3) + 1);
      offset = 0;
      speed = (randint(4) + 1) / 4.0;
      totalage /= speed;
      direction = randint(2)*2-1;
    }
    if (name == "scaleX" || name == "scaleY") {
      totalage = scaleFactor * (randint(3) + 1);
      offset = 0;
      speed = (randint(4) + 1) / 1024.0;
      totalage /= speed;
    }
    if (name == "circle") {
      totalage = 360;
      offset = 0;
      speed = (randint(8) + 1);
      totalage /= speed;
      direction = randint(2)*2-1;
    }
    age = 0;
  }
  void iter() {
    age += 1;
    if (name == "shakeH" || name == "shakeV" || name == "rotate" || name == "scaleX" || name == "scaleY") {
      float relative = age;
      if (relative >= 0 && relative < totalage / 4.0) {
        offset -= speed * direction;
      }
      if (relative >= totalage / 4.0 && relative < totalage * 3/ 4.0) {
        offset += speed * direction;
      }
      if (relative >= totalage * 3 / 4.0 && relative < totalage) {
        offset -= speed * direction;
      }
      if (name == "shakeH") translate(offset, 0);
      if (name == "shakeV") translate(0, offset);
      if (name == "rotate") {
        translate(WIDTH/2, HEIGHT/2);
        rotate(radians(offset/3.5));
        translate(-WIDTH/2, -HEIGHT/2);
      }
      if (name == "scaleX") {
        translate(WIDTH/2, HEIGHT/2);
        scale(1+offset, 1);
        translate(-WIDTH/2, -HEIGHT/2);
      }
      if (name == "scaleY") {
        translate(WIDTH/2, HEIGHT/2);
        scale(1, 1+offset);
        translate(-WIDTH/2, -HEIGHT/2);
      }
    }
    if (name == "circle") {
      offset += speed * direction;
      translate(WIDTH/2, HEIGHT/2);
      rotate(radians(offset));
      scale(1-(1-abs(180-abs(offset/speed))/180), 1-(1-abs(180-abs(offset/speed))/180));
      translate(-WIDTH/2, -HEIGHT/2);
    }
    clear = age >= totalage;
  }
}

void setup() {
  rectMode(CORNERS);
  ellipseMode(CORNERS);
  
  surface.setSize(WIDTH, HEIGHT);
  font = loadFont("SansSerif-32.vlw");
  
  resetGameObjects();
}

void resetGameObjects() {
  score = 0;
  player = new Player();
  obstacles = new ArrayList<RSprite>();
  distractions = new ArrayList<Sprite>();
  transformations = new ArrayList<Transformation>();
}

RSprite createDistraction1() {
  return new RSprite("rcolorbox");
}

void draw() {
  score += 0.1;
  background(bg);
  
  if (state == "playing") {
    obstacleSpawnTimer -= 1;
    if (obstacleSpawnTimer <= 0) {
      obstacleSpawnTimer = obstacleSpawnReset;
      if (OBSTACLE) {
        obstacles.add(new Obstacle());
      }
    }
    
    for (int i=0; i<distractionMultiplier1; i++) {
      if (randint(distractionChance1) == 0 && filters && DIST1) {
        distractions.add(createDistraction1());
      }
    }
    
    if (randint(transformationChance1) == 0 && transformationsOfType("shakeH") < transformationMax1 && filters && SHAKEH) {
      transformations.add(new Transformation("shakeH"));
    }
    if (randint(transformationChance2) == 0 && transformationsOfType("shakeV") < transformationMax2 && filters && SHAKEV) {
      transformations.add(new Transformation("shakeV"));
    }
    if (randint(transformationChance3) == 0 && transformationsOfType("rotate") < transformationMax3 && filters && ROTATE) {
      transformations.add(new Transformation("rotate"));
    }
    if (randint(transformationChance4) == 0 && transformationsOfType("scaleX") < transformationMax4 && filters && SCALEX) {
      transformations.add(new Transformation("scaleX"));
    }
    if (randint(transformationChance5) == 0 && transformationsOfType("scaleY") < transformationMax5 && filters && SCALEY) {
      transformations.add(new Transformation("scaleY"));
    }
    if (randint(transformationChance6) == 0 && transformationsOfType("circle") < transformationMax6 && filters && CIRCLE) {
      transformations.add(new Transformation("circle"));
    }
    
    player.anim();
    for (int i=obstacles.size()-1; i>-1; i--) {
      RSprite sprite = obstacles.get(i);
      sprite.anim();
      if (sprite.clear) {
        obstacles.remove(i);
      }
    }
    
    for (int i=distractions.size()-1; i>-1; i--) {
      Sprite sprite = distractions.get(i);
      sprite.anim();
      if (sprite.clear) {
        distractions.remove(i);
      }
    }
    
    for (RSprite sprite : obstacles) {
      if (player.collide(sprite)) {
        sprite.c = color(255, 0, 0);
        state = "gameover";
        println("Game over! Your score was "+str(int(score))+"!");
      }
    }
  }
  if (state == "gameover") {
    if (keyDown(KeyEvent.VK_SPACE)) {
      resetGameObjects();
      state = "playing";
    }
  }
  
  for (int i=transformations.size()-1; i>-1; i--) {
    Transformation transformation = transformations.get(i);
    transformation.iter();
    if (transformation.clear) {
      transformations.remove(i);
    }
  }
  
  fill(0);
  stroke(0);
  rect(-BORDER, -BORDER, WIDTH-1, 0-1);
  rect(WIDTH, -BORDER, WIDTH + BORDER-1, HEIGHT-1);
  rect(0, HEIGHT, WIDTH + BORDER-1, HEIGHT + BORDER-1);
  rect(-BORDER, 0, 0-1, HEIGHT + BORDER-1);
  
  if (state == "playing") {
    player.draw();
    for (RSprite sprite : obstacles) {
      sprite.draw();
    }
    for (Sprite sprite : distractions) {
      sprite.draw();
    }
  }
  if (state == "gameover") {
    for (Sprite sprite : distractions) {
      sprite.draw();
    }
    player.draw();
    for (RSprite sprite : obstacles) {
      sprite.draw();
    }
    textFont(font, 32);
    fill(0);
    textAlign(CENTER, CENTER);
    text("Game over. Press space to continue.", WIDTH/2, HEIGHT/2);
  }
}

boolean keyDown(int code) {
  return keysDown.contains(code);
}

void keyPressed() {
  keysDown.add(keyEvent.getKeyCode());
}

void keyReleased() {
  keysDown.remove(keyEvent.getKeyCode());
}
