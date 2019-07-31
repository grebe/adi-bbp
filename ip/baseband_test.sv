`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2019 06:27:02 PM
// Design Name: 
// Module Name: baseband_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import axi_vip_pkg::*;
import test_bd_axi_vip_0_0_pkg::*;

module baseband_test(

    );

bit aclk = 0;
bit aresetn=0;
xil_axi_ulong     addr1=32'h79400100, addr2 = 32'h79400118, addr3 = 32'h79400110;
xil_axi_prot_t  prot = 0;
bit [31:0]     data_wr1=32'h1, data_wr2=32'h89ABCDEF,data_wr3=32'h0000FFFF;
bit [31:0]     data_rd1,data_rd2,data_rd3,data_rd4;
xil_axi_resp_t     resp;
always #5ns aclk = ~aclk;

test_wrapper DUT
(
    . clk (aclk),
    .aresetn(aresetn)
);

// Declare agent
test_bd_axi_vip_0_0_mst_t master_agent;

initial begin
  $dumpfile("out.vcd");
  $dumpvars(0, DUT.bd.Baseband_0);

  //Create an agent
  master_agent = new("master vip agent",DUT.bd.axi_vip_0.inst.IF);

  // set tag for agents for easy debug
  master_agent.set_agent_tag("Master VIP");

  // set print out verbosity level.
  master_agent.set_verbosity(400);

  //Start the agent
  master_agent.start_master();

  #50ns
  aresetn = 1;

  #100ns
  master_agent.AXI4LITE_WRITE_BURST(addr1,prot,data_wr1,resp);
  
  #100ns
  master_agent.AXI4LITE_WRITE_BURST(addr2,prot,data_wr2,resp);
  
  #100ns
  master_agent.AXI4LITE_READ_BURST(addr1,prot,data_rd1,resp);
  
  #100ns
  master_agent.AXI4LITE_READ_BURST(addr2,prot,data_rd2,resp);
  
  #100ns
  if((data_wr1 == data_rd1)&&(data_wr2 == data_rd2))
    $display("Data match, test succeeded");
  else
    $display("Data do not match, test failed");

  #100ns
  master_agent.AXI4LITE_WRITE_BURST(addr1,prot,data_wr1,resp);
  
  #100ns
  master_agent.AXI4LITE_WRITE_BURST(addr2,prot,data_wr3,resp);
  
  #100ns
  master_agent.AXI4LITE_READ_BURST(addr1,prot,data_rd1,resp);
  
  #100ns
  master_agent.AXI4LITE_READ_BURST(addr2,prot,data_rd3,resp);

  #100ns
  master_agent.AXI4LITE_READ_BURST(addr3,prot,data_rd4,resp);
  
  #100ns
  if((data_wr1 == data_rd1)&&(data_wr3 == data_rd3))
    $display("Data match, test succeeded");
  else
    $display("Data do not match, test failed");

  
  #200
  $finish;

end

endmodule
