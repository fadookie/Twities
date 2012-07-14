class Quads implements Polygons {
  ArrayList<Coordinate> coords = new ArrayList();
  PImage texture;

  Quads(PImage texture) {
    this.texture = texture;
  }
  /**
   * Helper for building flat quads
   */
  void addQuad(int texDirection, float uMin, float vMin, float uMax, float vMax, PVector pos, PVector size) {
    UVCoord t1 = null, t2 = null, t3 = null, t4 = null,
            t1tmp = new UVCoord(),
            t2tmp = new UVCoord(),
            t3tmp = new UVCoord(),
            t4tmp = new UVCoord();

    //Temp coordinates are in clockwise orientation
    t1tmp.u = uMin; t1tmp.v = vMin;
    t2tmp.u = uMax; t2tmp.v = vMin;
    t3tmp.u = uMax; t3tmp.v = vMax;
    t4tmp.u = uMin; t4tmp.v = vMax;

    switch(texDirection) {
      case TEX_DIRECTION_FORWARD:
        //Default clockwise orientation
        t1 = t1tmp;
        t2 = t2tmp;
        t3 = t3tmp;
        t4 = t4tmp;
        break;
      case TEX_DIRECTION_BACK:
        //Clockwise from point 3
        t1 = t3tmp;
        t2 = t4tmp;
        t3 = t1tmp;
        t4 = t2tmp;
        break;
      case TEX_DIRECTION_LEFT:
        //Clockwise from point 2
        t1 = t2tmp;
        t2 = t3tmp;
        t3 = t4tmp;
        t4 = t1tmp;
        break;
      case TEX_DIRECTION_RIGHT:
        //Clockwise from point 4
        t1 = t4tmp;
        t2 = t1tmp;
        t3 = t2tmp;
        t4 = t3tmp;
        break;
    }
    coords.add(new Coordinate(pos.x, pos.y, pos.z, t1.u, t1.v));
    coords.add(new Coordinate(pos.x + size.x, pos.y, pos.z, t2.u, t2.v));
    coords.add(new Coordinate(pos.x + size.x, pos.y + size.y, pos.z + size.z, t3.u, t3.v));
    coords.add(new Coordinate(pos.x, pos.y + size.y, pos.z + size.z, t4.u, t4.v));
  }

  void draw() {
    PGraphicsOpenGL pgl = (PGraphicsOpenGL)g;

    for (int i = 0; i < coords.size(); i += 4) {
      beginShape(QUADS);

      pgl.textureSampling(Texture.LINEAR);
      pgl.textureWrap(Texture.REPEAT); //Set texture wrap mode to GL_REPEAT. See http://code.google.com/p/processing/issues/detail?id=94
      textureMode(NORMAL);

      if (texture != null) {
        texture(texture);
      }

      for (int j = i; j < i + 4; j++) {
        Coordinate c = coords.get(j);
        vertex(c.pos.x, c.pos.y, c.pos.z, c.u, c.v);
      }

      endShape();
    }
  }
}
