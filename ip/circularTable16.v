
module circularTable16(
  input                                    clock,
  input      [3:0] addr,
  output reg [16:0] data
);
  always @(posedge clock) begin
    case (addr)
      4'b0: data <= 17'h19220;
      4'b1: data <= 17'hed63;
      4'b10: data <= 17'h7d6e;
      4'b11: data <= 17'h3fab;
      4'b100: data <= 17'h1ff5;
      4'b101: data <= 17'hfff;
      4'b110: data <= 17'h800;
      4'b111: data <= 17'h400;
      4'b1000: data <= 17'h200;
      4'b1001: data <= 17'h100;
      4'b1010: data <= 17'h80;
      4'b1011: data <= 17'h40;
      4'b1100: data <= 17'h20;
      4'b1101: data <= 17'h10;
      4'b1110: data <= 17'h8;
      4'b1111: data <= 17'h4;

      default: data <= 17'h0;
    endcase
  end
endmodule
     