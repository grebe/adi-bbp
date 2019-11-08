
module NCOTableLUT(
  input                                    clock,
  input      [5:0] addr,
  output reg [13:0] data
);
  always @(posedge clock) begin
    case (addr)
      6'b0: data <= 14'h0;
      6'b1: data <= 14'h192;
      6'b10: data <= 14'h324;
      6'b11: data <= 14'h4b5;
      6'b100: data <= 14'h646;
      6'b101: data <= 14'h7d6;
      6'b110: data <= 14'h964;
      6'b111: data <= 14'haf1;
      6'b1000: data <= 14'hc7c;
      6'b1001: data <= 14'he06;
      6'b1010: data <= 14'hf8d;
      6'b1011: data <= 14'h1112;
      6'b1100: data <= 14'h1294;
      6'b1101: data <= 14'h1413;
      6'b1110: data <= 14'h1590;
      6'b1111: data <= 14'h1709;
      6'b10000: data <= 14'h187e;
      6'b10001: data <= 14'h19ef;
      6'b10010: data <= 14'h1b5d;
      6'b10011: data <= 14'h1cc6;
      6'b10100: data <= 14'h1e2b;
      6'b10101: data <= 14'h1f8c;
      6'b10110: data <= 14'h20e7;
      6'b10111: data <= 14'h223d;
      6'b11000: data <= 14'h238e;
      6'b11001: data <= 14'h24da;
      6'b11010: data <= 14'h2620;
      6'b11011: data <= 14'h2760;
      6'b11100: data <= 14'h289a;
      6'b11101: data <= 14'h29ce;
      6'b11110: data <= 14'h2afb;
      6'b11111: data <= 14'h2c21;
      6'b100000: data <= 14'h2d41;
      6'b100001: data <= 14'h2e5a;
      6'b100010: data <= 14'h2f6c;
      6'b100011: data <= 14'h3076;
      6'b100100: data <= 14'h3179;
      6'b100101: data <= 14'h3274;
      6'b100110: data <= 14'h3368;
      6'b100111: data <= 14'h3453;
      6'b101000: data <= 14'h3537;
      6'b101001: data <= 14'h3612;
      6'b101010: data <= 14'h36e5;
      6'b101011: data <= 14'h37b0;
      6'b101100: data <= 14'h3871;
      6'b101101: data <= 14'h392b;
      6'b101110: data <= 14'h39db;
      6'b101111: data <= 14'h3a82;
      6'b110000: data <= 14'h3b21;
      6'b110001: data <= 14'h3bb6;
      6'b110010: data <= 14'h3c42;
      6'b110011: data <= 14'h3cc5;
      6'b110100: data <= 14'h3d3f;
      6'b110101: data <= 14'h3daf;
      6'b110110: data <= 14'h3e15;
      6'b110111: data <= 14'h3e72;
      6'b111000: data <= 14'h3ec5;
      6'b111001: data <= 14'h3f0f;
      6'b111010: data <= 14'h3f4f;
      6'b111011: data <= 14'h3f85;
      6'b111100: data <= 14'h3fb1;
      6'b111101: data <= 14'h3fd4;
      6'b111110: data <= 14'h3fec;
      6'b111111: data <= 14'h3ffb;

      default: data <= 14'h0;
    endcase
  end
endmodule
     