module test_wrapper
(
  input clk,
  input aresetn
);
  test_bd bd(
    .clock(clk),
    .aresetn(aresetn),
    .reset(~aresetn)
  );

endmodule
