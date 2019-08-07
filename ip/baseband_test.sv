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
import test_bd_axi_vip_master_0_pkg::*;
import test_bd_axi_vip_slave_0_pkg::*;

import axi4stream_vip_pkg::*;
import test_bd_axi4stream_vip_master_0_pkg::*;

module baseband_test();

bit aclk = 0;
bit aresetn=0;
xil_axi_ulong dma_base=32'h79400000;
xil_axi_ulong aligner_base=32'h79400100;
xil_axi_prot_t  prot = 0;
bit [31:0]     data_rd;
bit [63:0] remaining;
xil_axi4stream_data_byte data[3:0] = '{8'b0, 8'b0, 8'b0, 8'b0};
xil_axi_resp_t     resp;
axi4stream_transaction stream_trans;
always #5ns aclk = ~aclk;

test_wrapper DUT
(
    . clk (aclk),
    .aresetn(aresetn)
);

// declare agents
test_bd_axi_vip_master_0_mst_t mem_master_agent;
test_bd_axi4stream_vip_master_0_mst_t stream_master_agent;
test_bd_axi_vip_slave_0_slv_mem_t mem_slave_agent;

initial begin
  $dumpfile("out.vcd");
  $dumpvars(0, DUT.bd.Baseband_0);

  // create agents
  mem_master_agent = new("mem master vip agent", DUT.bd.axi_vip_master.inst.IF);
  stream_master_agent = new("stream master vip agent", DUT.bd.axi4stream_vip_master.inst.IF);
  mem_slave_agent = new("mem slave vip agent", DUT.bd.axi_vip_slave.inst.IF);

  // set tag for agents for easy debug
  mem_master_agent.set_agent_tag("Mem Master VIP");
  stream_master_agent.set_agent_tag("Stream Master VIP");
  mem_slave_agent.set_agent_tag("Mem Slave VIP");

  // set print out verbosity level.
  // mem_master_agent.set_verbosity(400);
  mem_slave_agent.set_verbosity(400);

  //Start the agent
  mem_master_agent.start_master();
  stream_master_agent.start_master();
  mem_slave_agent.start_slave();

  #50ns
  aresetn = 1;

  // initialize the aligner
  // set maxCnt
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'hC, prot,'h20, resp);
  // set en
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h1, resp);
  // initialize dma engine
  // set en
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h0, prot, 'h1, resp);
  // set base
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h10, prot, 'h0, resp);
  // set length
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h14, prot, 'd10, resp);
  // set cycles
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h18, prot, 'h0, resp);

  fork
    // run the dma until it is over
    begin
      mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h20, prot, 'h0, resp);
      do
      begin
        mem_master_agent.AXI4LITE_READ_BURST(dma_base + 'h20, prot, remaining, resp);
      end
      while (remaining != 0);
    end

    // feed the streaming input
    begin
      stream_trans = stream_master_agent.driver.create_transaction("write transaction");
      stream_trans.set_id('h0);
      stream_trans.set_dest('h0);
      for (int i = 0; i < 100; i++) begin
        data[0] = i & 8'hFF;
        data[1] = (i >> 8) & 8'hFF;
        data[2] = (i >> 16) & 8'hFF;
        data[3] = (i >> 24) & 8'hFF;
        stream_trans.set_data(data);
        stream_master_agent.driver.send(stream_trans);
      end
    end

  join_any

  #500 // take plenty of time for the write transaction to actually finish
  for (int i = 0; i < 11; i++) begin
    data_rd = mem_slave_agent.mem_model.backdoor_memory_read_4byte(i * 4);
    $display("%x", data_rd);
  end

  #200
  $finish;

end

endmodule
