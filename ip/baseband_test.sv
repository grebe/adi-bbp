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
import test_bd_axi4stream_vip_slave_0_pkg::*;

module baseband_test();

bit aclk = 0;
bit rxclk = 0;
bit aresetn=0;
bit rxresetn = 0;
xil_axi_ulong dma_base=32'h79400000;
xil_axi_ulong aligner_base=32'h79400100;
xil_axi_ulong skid_base=32'h79400200;
xil_axi_ulong stream_mux_base=32'h79400300;
xil_axi_ulong ram_base=32'h79044000;
xil_axi_ulong tx_length=32'h1F;
xil_axi_prot_t  prot = 0;
bit [31:0]     data_rd;
bit [63:0] remaining;
xil_axi4stream_data_byte data[3:0] = '{8'b0, 8'b0, 8'b0, 8'b0};
xil_axi_resp_t     resp;
axi4stream_transaction stream_trans;
always #5ns aclk = ~aclk;
always #20ns rxclk = ~rxclk;

test_wrapper DUT
(
    . clk (aclk),
    .rxclk(rxclk),
    .aresetn(aresetn),
    .rxresetn(rxresetn)
);

// declare agents
test_bd_axi_vip_master_0_mst_t mem_master_agent;
test_bd_axi4stream_vip_master_0_mst_t stream_master_agent;
test_bd_axi4stream_vip_slave_0_slv_t stream_slave_agent;
test_bd_axi_vip_slave_0_slv_mem_t mem_slave_agent;

initial begin
  $dumpfile("out.vcd");
  $dumpvars(0, DUT.bd.Baseband_0);

  // create agents
  mem_master_agent = new("mem master vip agent", DUT.bd.axi_vip_master.inst.IF);
  stream_master_agent = new("stream master vip agent", DUT.bd.axi4stream_vip_master.inst.IF);
  stream_slave_agent = new("stream slave vip agent", DUT.bd.axi4stream_vip_slave.inst.IF);
  mem_slave_agent = new("mem slave vip agent", DUT.bd.axi_vip_slave.inst.IF);

  // set tag for agents for easy debug
  mem_master_agent.set_agent_tag("Mem Master VIP");
  stream_master_agent.set_agent_tag("Stream Master VIP");
  stream_slave_agent.set_agent_tag("Stream Slave VIP");
  mem_slave_agent.set_agent_tag("Mem Slave VIP");

  // set print out verbosity level.
  // mem_master_agent.set_verbosity(400);
  mem_slave_agent.set_verbosity(400);

  //Start the agent
  mem_master_agent.start_master();
  stream_master_agent.start_master();
  stream_slave_agent.start_slave();
  mem_slave_agent.start_slave();

  #50ns
  aresetn = 1;
  rxresetn = 1;

  // initialize ram
  for (int i = 0; i <= tx_length; i++) begin
    mem_master_agent.AXI4LITE_WRITE_BURST(ram_base + i * 4, prot, i, resp);
  end
  // start tx
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h0, prot, 'h1, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h24, prot, ram_base, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h28, prot, tx_length, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h2C, prot, 'h4, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h34, prot, 'h0, resp);

  // initialize the aligner
  // set maxCnt
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'hC, prot,'h20, resp);
  // set cnt passthrough
  // mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h10, prot,'h1, resp);
  // set en on aligner
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h1, resp);
  // enable the skid buffer
  mem_master_agent.AXI4LITE_WRITE_BURST(skid_base + 'h0, prot, 'h1, resp);
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
      for (int i = 0; i < 'h20; i++) begin
        data[0] = i & 8'hFF;
        data[1] = (i >> 8) & 8'hFF;
        data[2] = (i >> 16) & 8'hFF;
        data[3] = (i >> 24) & 8'hFF;
        stream_trans.set_data(data);
        stream_master_agent.driver.send(stream_trans);
      end
    end

  join

  #500 // take plenty of time for the write transaction to actually finish
  for (int i = 0; i < 11; i++) begin
    data_rd = mem_slave_agent.mem_model.backdoor_memory_read_4byte(i * 4);
    $display("%x", data_rd);
  end

  #200;

  mem_master_agent.AXI4LITE_WRITE_BURST(stream_mux_base + 'h0, prot, 'h1, resp);

  #3000;
  $finish;

  // reset en on aligner and skid
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h0, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(skid_base + 'h0, prot, 'h0, resp);
  #200;
  mem_master_agent.AXI4LITE_WRITE_BURST(skid_base + 'h0, prot, 'h1, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h1, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h10, prot, 'h100, resp);
  // set length
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h14, prot, 'd257 * 'd2, resp);
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
      for (int i = 0; i < 1024 * 2; i++) begin
        data[0] = i & 8'hFF;
        data[1] = (i >> 8) & 8'hFF;
        data[2] = (i >> 16) & 8'hFF;
        data[3] = (i >> 24) & 8'hFF;
        stream_trans.set_data(data);
        stream_master_agent.driver.send(stream_trans);
      end
    end

  join

  #500 // take plenty of time for the write transaction to actually finish
  for (int i = 0; i < 11; i++) begin
    data_rd = mem_slave_agent.mem_model.backdoor_memory_read_4byte('h100 + i * 4);
    $display("%x", data_rd);
  end

  // reset en on aligner and skid
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h0, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(skid_base + 'h0, prot, 'h0, resp);
  #200;
  mem_master_agent.AXI4LITE_WRITE_BURST(skid_base + 'h0, prot, 'h1, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(aligner_base + 'h0, prot,'h1, resp);
  mem_master_agent.AXI4LITE_WRITE_BURST(dma_base + 'h10, prot, 'h100, resp);
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

  join

  #500 // take plenty of time for the write transaction to actually finish
  for (int i = 0; i < 11; i++) begin
    data_rd = mem_slave_agent.mem_model.backdoor_memory_read_4byte('h100 + i * 4);
    $display("%x", data_rd);
  end


  #200
  $finish;

end

endmodule
