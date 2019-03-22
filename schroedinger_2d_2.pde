
float[][] re;
float[][] im;
float[][] dre;
float[][] dim;

float getLaplacian(float[][] F, int x, int y) {
  float laplacian = 0;
  for(int i=-1;i<=1;i++) {
  for(int j=-1;j<=1;j++) {
    int u=x+i; if(u<0 || u>=F.length) { continue; }
    int v=y+j; if(v<0 || v>=F[0].length) { continue; }
    float f = F[u][v];
    if(i!=0 || j!=0) {
      if(i!=0 && j!=0) {
        f *= 0.05;
      } else {
        f *= 0.2;
      }
    } else {
      f *= -1;
    }
    laplacian += f;
  }
  }
  return laplacian;
}

void applyTension(float[][] F, float[][] dF, float k) {
  for(int i=0;i<F.length;i++) {
  for(int j=0;j<F[0].length;j++) {
    dF[i][j] = getLaplacian(F,i,j)*k;
  }
  }
}

void applyChange(float[][] F, float[][] dF, float dt) {
  for(int i=0;i<F.length;i++) {
  for(int j=0;j<F[0].length;j++) {
    F[i][j] += dF[i][j]*dt;
  }
  }
}

void schroedinger() {
  float k = 0.1;
  float dt = 0.1;
  applyTension(re,dim,k);
  applyTension(im,dre,-k);
  applyChange(re,dre,dt);
  applyChange(im,dim,dt);
}

void createWave(
    float[][] re, float[][] im,
    float x, float y,
    float vx, float vy,
    float amp) {
  for(int i=0;i<re.length;i++) {
  for(int j=0;j<re[0].length;j++) {
    float dx = (float)i/(re.length-1)*width-x;
    float dy = (float)j/(im.length-1)*height-y;
    float mag = amp/((dx*dx+dy*dy)/100.+1);
    float ang = (i*vx+j*vy)/3.;
    re[i][j] += mag*cos(ang);
    im[i][j] += mag*sin(ang);
  }
  }
}

void setup() {
  
  size(640,640);
  noSmooth();
  
  int width = 100;
  int height = 100;
  re = new float[width][height];
  im = new float[width][height];
  dre = new float[width][height];
  dim = new float[width][height];
}

void keyPressed() {
  switch(key) {
    case 'n':
      createWave(re,im,mouseX,mouseY,
          (mouseX-pmouseX)*.2,
          (mouseY-pmouseY)*.2,255);
    break;
    case 'c':
      for(int i=0;i<re.length;i++) {
      for(int j=0;j<re[0].length;j++) {
        re[i][j] = 0;
        im[i][j] = 0;
      }
      }
    break;
  }
}

void draw() {
  
  noStroke();
  float tile_w = (float)width/re.length;
  float tile_h = (float)height/re[0].length;
  for(int i=0;i<re.length;i++) {
  for(int j=0;j<re[0].length;j++) {
    fill(abs(re[i][j])*10,0,abs(im[i][j])*10);
    rect(i*tile_w,j*tile_h,tile_w,tile_h);
  }
  }
  
  for(int i=0;i<10;i++) {
    schroedinger();
  }
  
  surface.setTitle("FPS: "+frameRate);
}

/*
PShader schroedinger;
PGraphics canvas;
PGraphics output;

float[][] out;

void clearCanvas() {
  canvas.beginDraw();
  schroedinger.set("mode",3);
  canvas.filter(schroedinger);
  canvas.endDraw();
}

void setup() {
  
  size(640,640,P3D);
  noSmooth();
  
  {
    int width = 100;
    int height = 100;
    
    canvas = createGraphics(width,height,P2D);
    output = createGraphics(width,height,P2D);
    
    out = new float[width][height];
  }
  
  schroedinger = loadShader("schroedinger.glsl");
  schroedinger.set("canvas",canvas);
  schroedinger.set("k",.1);
  schroedinger.set("dt",.1);
  
  clearCanvas();
  
}

void keyPressed() {
  switch(key) {
    case 'n':
      // y-coordinates are flipped
      int mouseY = height-this.mouseY;
      int pmouseY = height-this.pmouseY;
      canvas.beginDraw();
      schroedinger.set("mode",1);
      schroedinger.set("pos",
          (float)mouseX/(width-1)*(canvas.width-1),
          (float)mouseY/(height-1)*(canvas.height-1));
      schroedinger.set("vel",
          (float)(mouseX-pmouseX)*.05,
          (float)(mouseY-pmouseY)*.05);
      schroedinger.set("rad",2.0);
      schroedinger.set("mag",1.0);
      canvas.filter(schroedinger);
      canvas.endDraw();
    break;
    case 'c':
      clearCanvas();
    break;
  }
}

void drawMesh(float[][] x, float scale, float height) {
  for(int i=0;i<x.length;i++) {
  for(int j=0;j<x[0].length;j++) {
    float u = i*scale;
    float v = j*scale;
    if(i>0) { line(u,x[i][j]*height,v,u+scale,x[i-1][j]*height,v); }
    if(j>0) { line(u,x[i][j]*height,v,u,x[i][j-1]*height,v+scale); }
  }
  }
}

float[][] re(float[][] out, PGraphics output) {
  for(int i=0;i<out.length;i++) {
  for(int j=0;j<out[0].length;j++) {
    out[i][j] = (red(output.pixels[i+j*output.width])/255-.5)*2;
  }
  }
  return out;
}

float[][] im(float[][] out, PGraphics output) {
  for(int i=0;i<out.length;i++) {
  for(int j=0;j<out[0].length;j++) {
    out[i][j] = (blue(output.pixels[i+j*output.width])/255-.5)*2;
  }
  }
  return out;
}

void draw() {
  
  canvas.beginDraw();
  schroedinger.set("mode",2);
  for(int i=0;i<20;i++) {
    canvas.filter(schroedinger);
  }
  canvas.endDraw();
  
  output.beginDraw();
  schroedinger.set("mode",0);
  output.filter(schroedinger);
  output.endDraw();
  
  image(output,0,0,width,height);
  
  if(false) {
  float scale = 10;
  
  translate(
      width/2,
      height/2,
      0);
  rotateY(mouseX*0.02);
  rotateX(mouseY*0.02);
  translate(
      -scale*output.width/2,
      0,
      -scale*output.height/2);
  background(0);
  output.loadPixels();
  stroke(255,0,0); drawMesh(re(out,output),scale,10);
  stroke(0,0,255); drawMesh(im(out,output),scale,10);
  }
  
  surface.setTitle("FPS: "+frameRate);
}
*/
