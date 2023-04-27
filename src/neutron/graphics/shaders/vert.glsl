attribute vec2 pos;
attribute vec2 texcoord;
varying vec2 v_texcoord;

void main() {
  gl_Position = vec4(pos, 1.0, 1.0);
  v_texcoord = texcoord;
}
