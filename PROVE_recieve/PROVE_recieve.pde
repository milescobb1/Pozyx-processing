import oscP5.*;
import org.gwoptics.graphics.graph2D.Graph2D;
import org.gwoptics.graphics.graph2D.traces.*;
import org.gwoptics.graphics.graph2D.backgrounds.*;
import org.gwoptics.graphics.GWColour;
import processing.serial.*;
import java.lang.Math.*;

boolean serial = false;          // set to true to use Serial, false to use OSC messages.

int oscPort = 8888;               // change this to your UDP port
String serialPort = "COM13";      // change this to your COM port 


/////////////////////////////////////////////////////////////
//////////////////////  variables //////////////////////////
/////////////////////////////////////////////////////////////

OscP5 oscP5;
Serial myPort;

Graph[] graphs = new Graph[6];
int     lf = 10;       //ASCII linefeed
String  inString;      //String for testing serial communication
int[] rgb_color = {0, 0, 255, 0, 160, 122, 0, 255, 0, 255};

/////////////////////////////////////////////////////////////
///////////// sensordata variables //////////////////////////
/////////////////////////////////////////////////////////////

float x_angle = 0;  
float y_angle = 0;
float z_angle = 0;

float speed_x = 0;
float speed_y = 0;
float speed_z = 0;

float lin_acc_x = 0;
float lin_acc_y = 0;
float lin_acc_z = 0;

float quat_w, quat_x, quat_y, quat_z;
float grav_x, grav_y, grav_z;
float heading = 0;
float pressure = 0;

String calib_status = "";

/////////////////////////////////////////////////////////////
///////// class needed for the timeseries graph /////////////
/////////////////////////////////////////////////////////////

class rangeData implements ILine2DEquation{
    private double curVal = 0;

    public void setCurVal(double curVal) {
      this.curVal = curVal;      
    }
    
    public double getCurVal() {
      return this.curVal;
    }
    
    public double computePoint(double x,int pos) {
      return curVal;
    }
}

class Graph {
  public Graph2D chart;
  public ArrayList<rangeData> data;
  
  Graph(Graph2D chart, ArrayList<rangeData> data) {
    this.chart = chart;
    this.data = data;
  }
}

void setup(){
  println("setting up");
  size(1100,800, P3D);
  surface.setResizable(true);
  stroke(0,0,0);
  colorMode(RGB, 256); 
 
  if(serial){
    try{
      myPort = new Serial(this, serialPort, 115200);
      myPort.clear();
      myPort.bufferUntil(lf);
    }catch(Exception e){
      println("Cannot open serial port.");
    }
  }else{
    try{
      oscP5 = new OscP5(this, oscPort);
    }catch(Exception e){
      println("Cannot open UDP port");
    }
  }
  for(int ii = 0; ii < 6; ii++)
  {
    graphs[ii] = new Graph(new Graph2D(this, 400, 75, false), new ArrayList<rangeData>());
  }

  for(int ii = 0; ii < 6; ii++){
    rangeData r = new rangeData();
    graphs[ii].data.add(r);
    RollingLine2DTrace rl = new RollingLine2DTrace(r ,100,0.1f);
    rl.setTraceColour(rgb_color[6], rgb_color[7], rgb_color[8]);
    rl.setLineWidth(2);
    graphs[ii].chart.addTrace(rl);
    graphs[ii].chart.setYAxisMin(-2.0f);
    graphs[ii].chart.setYAxisMax(2.0f);
    graphs[ii].chart.position.y = 130*ii+10;
    graphs[ii].chart.position.x = 75;    
    graphs[ii].chart.setYAxisTickSpacing(1f);
    graphs[ii].chart.setXAxisTickSpacing(2f);
    graphs[ii].chart.setXAxisMax(15f);
    graphs[ii].chart.setXAxisMin(0f);
    graphs[ii].chart.setFontColour(255,255,255);
    graphs[ii].chart.setXAxisLabel("Time (s)");
    graphs[ii].chart.setYAxisLabel("Power " + (1+ii));
    graphs[ii].chart.setBackground(new SolidColourBackground(new GWColour(1f,1f,1f)));
  }
}

void draw(){
    background(0,0,0);
       
    // show some text
    fill(0,0,0);
    text("(c) Pozyx Labs", width-100, 20);
    text("Calibration status:", 550, 730);
    text(calib_status, 550, 750);   
       
    // draw the graphs
    for(int ii = 0; ii < 6; ii++) {
      if(graphs[ii] != null)
      {
        graphs[ii].chart.draw();
      }
    }
}


void serialEvent(Serial p) {
  
  inString = (myPort.readString());
  println(inString);  
  
  try {
    //Parse the data
    String[] dataStrings = split(inString, ',');
    
    for(Graph graph: graphs) {
      graph.data.get(0).setCurVal(float(dataStrings[2])/1000.0f);
    }
    
    for(int ii =0; ii < 6; ii++) {
      print(dataStrings[ii]);
      //graphs[ii].data.get(ii).setCurVal(dataStrings[ii]);
    }

    // the calibration status
    calib_status = "Mag: " + dataStrings[24] + " - Acc: " + dataStrings[25] + " - Gyro: " + dataStrings[26] + " - System: " + dataStrings[27];
                
  } catch (Exception e) {
      println("Error while reading serial data.");
  }
}

void draw_rect(int r, int g, int b) {
  scale(100);
  beginShape(QUADS);
  
  fill(r, g, b);
  vertex(-1,  1.5,  0.25);
  vertex( 1,  1.5,  0.25);
  vertex( 1, -1.5,  0.25);
  vertex(-1, -1.5,  0.25);

  vertex( 1,  1.5,  0.25);
  vertex( 1,  1.5, -0.25);
  vertex( 1, -1.5, -0.25);
  vertex( 1, -1.5,  0.25);

  vertex( 1,  1.5, -0.25);
  vertex(-1,  1.5, -0.25);
  vertex(-1, -1.5, -0.25);
  vertex( 1, -1.5, -0.25);

  vertex(-1,  1.5, -0.25);
  vertex(-1,  1.5,  0.25);
  vertex(-1, -1.5,  0.25);
  vertex(-1, -1.5, -0.25);

  vertex(-1,  1.5, -0.25);
  vertex( 1,  1.5, -0.25);
  vertex( 1,  1.5,  0.25);
  vertex(-1,  1.5,  0.25);

  vertex(-1, -1.5, -0.25);
  vertex( 1, -1.5, -0.25);
  vertex( 1, -1.5,  0.25);
  vertex(-1, -1.5,  0.25);

  endShape();
  
}

public void quat_rotate(float w, float x, float y, float z) {
   float _x, _y, _z;
   //if (q1.w > 1) q1.normalise(); // if w>1 acos and sqrt will produce errors, this cant happen if quaternion is normalised
   double angle = 2 * Math.acos(w);
   float s = (float)Math.sqrt(1-w*w); // assuming quaternion normalised then w is less than 1, so term always positive.
   if (s < 0.001) { // test to avoid divide by zero, s is always positive due to sqrt
     // if s close to zero then direction of axis not important
     _x = x; // if it is important that axis is normalised then replace with x=1; y=z=0;
     _y = y;
     _z = z;
   } else {
     _x = x / s; // normalise axis
     _y = y / s;
     _z = z / s;
   }
   rotate((float)angle, _x, _y, _z);     
}

public final PVector quaternion_rotate(float w, float x, float y, float z, PVector v) { 
      
      float q00 = 2.0f * x * x;
      float q11 = 2.0f * y * y;
      float q22 = 2.0f * z * z;

      float q01 = 2.0f * x * y;
      float q02 = 2.0f * x * z;
      float q03 = 2.0f * x * w;

      float q12 = 2.0f * y * z;
      float q13 = 2.0f * y * w;

      float q23 = 2.0f * z * w;

      return new PVector((1.0f - q11 - q22) * v.x + (q01 - q23) * v.y
                      + (q02 + q13) * v.z, (q01 + q23) * v.x + (1.0f - q22 - q00) * v.y
                      + (q12 - q03) * v.z, (q02 - q13) * v.x + (q12 + q03) * v.y
                      + (1.0f - q11 - q00) * v.z);
      
}