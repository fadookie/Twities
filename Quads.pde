class Quads implements Polygons {
  ArrayList<Coordinate> coords = new ArrayList();
  PImage texture;

  Quads(PImage texture) {
    this.texture = texture;
  }
  /**
   * Helper for building flat quads
   */
  void addQuad(float textureScaleU, float textureScaleV, PVector pos, PVector size) {
    coords.add(new Coordinate(pos.x, pos.y, pos.z, 0, 0));
    coords.add(new Coordinate(pos.x + size.x, pos.y, pos.z, textureScaleU, 0));
    coords.add(new Coordinate(pos.x + size.x, pos.y + size.y, pos.z + size.z, textureScaleU, textureScaleV));
    coords.add(new Coordinate(pos.x, pos.y + size.y, pos.z + size.z, 0, textureScaleV));
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
