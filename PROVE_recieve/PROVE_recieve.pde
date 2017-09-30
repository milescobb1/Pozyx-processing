import org.gwoptics.graphics.graph2D.Graph2D;
import org.gwoptics.graphics.graph2D.traces.*;
import org.gwoptics.graphics.graph2D.backgrounds.*;
import org.gwoptics.graphics.GWColour;
import processing.serial.*;
import java.lang.Math.*;

boolean serial = true;          // set to true to use Serial, false to use OSC messages.

String serialPort = "/dev/tty.usbmodem144231";      // change this to your COM port 

/////////////////////////////////////////////////////////////
//////////////////////  variables ///////////////////////////
/////////////////////////////////////////////////////////////

Serial myPort;

Graph[] power_graphs = new Graph[6];

Graph[] sus_graphs = new Graph[4];

Graph temp;

int     lf = 10;       //ASCII linefeed
String  inString;      //String for testing serial communication
int[] rgb_color = {0, 0, 255, 0, 160, 122, 0, 255, 0, 255};

String calib_status = "";

int powerMax = 500;

int powerMin = 200;

int susMax = 500;

int susMin = 200;

int tempMax = 500;

int tempMin = 200;

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
 
  // List all the available serial ports

  if(serial){
    try{
      printArray(Serial.list());
      // Open the port you are using at the rate you want:
      myPort = new Serial(this, Serial.list()[7], 9600);
      myPort.clear();
      myPort.bufferUntil(lf);
    }catch(Exception e){
      println("Cannot open serial port.");
    }
  }
  
  for(int ii=0; ii < power_graphs.length; ii++)
  {
    power_graphs[ii] = new Graph(new Graph2D(this, 400, 75, false), new ArrayList<rangeData>());
  }
  
  for(int ii=0; ii < sus_graphs.length; ii++)
  {
    sus_graphs[ii] = new Graph(new Graph2D(this, 400, 75, false), new ArrayList<rangeData>());
  }
  
  temp = new Graph(new Graph2D(this, 400, 75, false), new ArrayList<rangeData>());

  int ii = 0;
  for(Graph g: power_graphs){
    rangeData r = new rangeData();
    g.data.add(r);
    RollingLine2DTrace rl = new RollingLine2DTrace(r ,100,0.1f);
    rl.setTraceColour(rgb_color[6], rgb_color[7], rgb_color[8]);
    rl.setLineWidth(2);
    g.chart.addTrace(rl);
    g.chart.setYAxisMin(powerMin);
    g.chart.setYAxisMax(powerMax);
    g.chart.position.y = 130*ii+10;
    g.chart.position.x = 75;    
    g.chart.setYAxisTickSpacing((powerMax-powerMin)/5);
    g.chart.setXAxisTickSpacing(2f);
    g.chart.setXAxisMax(15f);
    g.chart.setXAxisMin(0f);
    g.chart.setFontColour(255, 255, 255);
    g.chart.setXAxisLabel("Time (s)");
    g.chart.setYAxisLabel("Power " + (1 + ii));
    g.chart.setBackground(new SolidColourBackground(new GWColour(1f, 1f, 1f)));
    ii ++;
  }
  ii = 0;
    for(Graph g: sus_graphs){
    rangeData r = new rangeData();
    g.data.add(r);
    RollingLine2DTrace rl = new RollingLine2DTrace(r, 100, 0.1f);
    rl.setTraceColour(rgb_color[6], rgb_color[7], rgb_color[8]);
    rl.setLineWidth(2);
    g.chart.addTrace(rl);
    g.chart.setYAxisMin(susMin);
    g.chart.setYAxisMax(susMax);
    g.chart.position.y = 130 * ii + 10;
    g.chart.position.x = 600;    
    g.chart.setYAxisTickSpacing((susMax-susMin)/5);
    g.chart.setXAxisTickSpacing(2f);
    g.chart.setXAxisMax(15f);
    g.chart.setXAxisMin(0f);
    g.chart.setFontColour(255, 255, 255);
    g.chart.setXAxisLabel("Time (s)");
    g.chart.setYAxisLabel("Suspension " + (1 + ii));
    g.chart.setBackground(new SolidColourBackground(new GWColour(1f, 1f, 1f)));
    ii ++;
  }
  
    rangeData r = new rangeData();
    temp.data.add(r);
    RollingLine2DTrace rl = new RollingLine2DTrace(r, 100, 0.1f);
    rl.setTraceColour(rgb_color[6], rgb_color[7], rgb_color[8]);
    rl.setLineWidth(2);
    temp.chart.addTrace(rl);
    temp.chart.setYAxisMin(tempMin);
    temp.chart.setYAxisMax(tempMax);
    temp.chart.position.y = 600;
    temp.chart.position.x = 600;    
    temp.chart.setYAxisTickSpacing((tempMax-tempMin)/5);
    temp.chart.setXAxisTickSpacing(2f);
    temp.chart.setXAxisMax(15f);
    temp.chart.setXAxisMin(0f);
    temp.chart.setFontColour(255, 255, 255);
    temp.chart.setXAxisLabel("Time (s)");
    temp.chart.setYAxisLabel("Temperature (C) " + (1 + ii));
    temp.chart.setBackground(new SolidColourBackground(new GWColour(1f, 1f, 1f)));
}

void draw(){
    background(0, 0, 0);
       
    // show some text
    fill(0, 0, 0);
    text("(c) Pozyx Labs", width - 100, 20);
    text("Calibration status:", 550, 730);
    text(calib_status, 550, 750);   
       
    // draw the graphs
    for(Graph g: power_graphs) {
      g.chart.draw();
    }
    
    for(Graph g: sus_graphs) {
      g.chart.draw();
    }
    
    temp.chart.draw();
}


void serialEvent(Serial p) {
  print(p);
  inString = (myPort.readString());
  println(inString);  
  
  try {
    //Parse the data
    String[] dataStrings = split(inString, ',');
    printArray(dataStrings);
    println(dataStrings.length);
    for(Graph g: power_graphs) {
      g.data.get(0).setCurVal(float(dataStrings[0]));
    }
    
    for(Graph g: sus_graphs) {
      g.data.get(0).setCurVal(float(dataStrings[1]));
    }
    
    temp.data.get(0).setCurVal(float(dataStrings[2]));
                
  } catch (Exception e) {
      println("Error while reading serial data. " + e);
  }
}