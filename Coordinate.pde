class Coordinate {
  PVector pos;
  float u;
  float v;

  Coordinate(float x, float y, float z, float u, float v) {
    pos = new PVector(x, y, z);
    this.u = u;
    this.v = v;
  }
}
