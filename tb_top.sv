module tb_top;

  //============================================================
  // 1. CLOCK AND RESET
  //============================================================
  logic pclk;
  logic dsi_rst;


  //============================================================
  // 2. INTERFACE INSTANCES
  //============================================================

  // AHB interface
  ahb_if ahb_vif (
    .pclk(pclk)
  );

  // Video / Pixel interface
  video_if video_vif (
    .pclk(pclk)
  );

  // PPI output interface
  ppi_if ppi_vif (
    .pclk(pclk)
  );


  //============================================================
  // 3. DUT INSTANTIATION
  //============================================================

  dsi #(
    .FRAME_LENGTH(1280),
    .FRAME_DEPTH(720)
  ) dut (

    // ---------------------------------------------------------
    // AHB INTERFACE
    // ---------------------------------------------------------
    .haddr  (ahb_vif.haddr),
    .hwrite (ahb_vif.hwrite),
    .hsize  (ahb_vif.hsize),
    .hburst (ahb_vif.hburst),
    .htrans (ahb_vif.htrans),
    .hwdata (ahb_vif.hwdata),
    .hprot  (ahb_vif.hprot),

    .hresp  (ahb_vif.hresp),
    .hready (ahb_vif.hready),
    .hrdata (ahb_vif.hrdata),


    // ---------------------------------------------------------
    // VIDEO / PIXEL INPUT
    // ---------------------------------------------------------
    .pixel_data (video_vif.pixel_data),
    .data_valid (video_vif.data_valid),
    .hsync      (video_vif.hsync),
    .vsync      (video_vif.vsync),
    .pclk       (pclk),

    .dsi_rst    (dsi_rst),


    // ---------------------------------------------------------
    // DSI CLOCK
    // ---------------------------------------------------------
    .dsi_clk (ppi_vif.dsi_clk),


    // ---------------------------------------------------------
    // PPI OUTPUT LANES
    // ---------------------------------------------------------
    .ppi_data_lane0 (ppi_vif.ppi_data_lane0),
    .ppi_data_lane1 (ppi_vif.ppi_data_lane1),
    .ppi_data_lane2 (ppi_vif.ppi_data_lane2),
    .ppi_data_lane3 (ppi_vif.ppi_data_lane3),

    .ppi_lane0_en   (ppi_vif.ppi_lane0_en),
    .ppi_lane1_en   (ppi_vif.ppi_lane1_en),
    .ppi_lane2_en   (ppi_vif.ppi_lane2_en),
    .ppi_lane3_en   (ppi_vif.ppi_lane3_en)
  );


  //============================================================
  // 4. CLOCK GENERATION
  //============================================================

  initial begin
    pclk = 0;

    forever begin
      #5 pclk = ~pclk;
    end
  end


  //============================================================
  // 5. RESET
  //============================================================

  initial begin
    dsi_rst = 1;

    repeat (5)
      @(posedge pclk);

    dsi_rst = 0;
  end


  //============================================================
  // 6. UVM CONFIGURATION
  //============================================================

  initial begin

    // AHB virtual interface
    uvm_config_db#(virtual ahb_if)::set(
      null,
      "*",
      "ahb_vif",
      ahb_vif
    );

    // Video virtual interface
    uvm_config_db#(virtual video_if)::set(
      null,
      "*",
      "video_vif",
      video_vif
    );

    // PPI virtual interface
    uvm_config_db#(virtual ppi_if)::set(
      null,
      "*",
      "ppi_vif",
      ppi_vif
    );

    run_test();
  end

endmodule