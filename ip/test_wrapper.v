module test_wrapper
(
  input clk,
  input rxclk,
  input aresetn,
  input rxresetn
);
  test_bd bd(
    .clock(clk),
    .rx_clock(rxclk),
    .aresetn(aresetn),
    .reset(~rxresetn),
    .resetn(rxresetn)
  );

endmodule
