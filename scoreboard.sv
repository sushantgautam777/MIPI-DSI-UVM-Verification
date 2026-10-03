`uvm_analysis_imp_decl(_DC)
`uvm_analysis_imp_decl(_PPI)

class mipi_dsi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mipi_dsi_scoreboard)

  uvm_analysis_imp_DC #(mipi_dc_seq_item,mipi_dsi_scoreboard) dc_imp;
  uvm_analysis_imp_PPI #(mipi_ppi_seq_item,mipi_dsi_scoreboard) ppi_imp;

  bit [23:0] expected_pixels[$];
  bit [7:0]  ppi_bytes[$];   // running byte stream from the PPI monitor

  // AA | FF | header(4) | payload | crc(2) | FF | BB
  parameter bit [7:0] START_BYTE = 8'hAA;
  parameter int PAYLOAD_LEN = `payload_cnt * 3;
  parameter int PKT_LEN     = PAYLOAD_LEN + 10;


  function new(string name="mipi_dsi_scoreboard",uvm_component parent=null);
    super.new(name,parent);
    dc_imp  = new("dc_imp",this);
    ppi_imp = new("ppi_imp",this);
  endfunction


  function void write_DC(mipi_dc_seq_item item);
    expected_pixels.delete();
    foreach(item.pixel_data[i])
      expected_pixels.push_back(item.pixel_data[i]);
    `uvm_info("SBD_DC",$sformatf("Expected pixel count = %0d",expected_pixels.size()),UVM_MEDIUM);
  endfunction


  function void write_PPI(mipi_ppi_seq_item item);

    bit [7:0] payload_bytes[$];
    bit [7:0] dropped_byte;   
    int pixel_count;
    bit [23:0] actual_pixel;

    // push this cycle's active-lane bytes
    if(item.ppi_lane0_en) ppi_bytes.push_back(item.ppi_data_lane0);
    if(item.ppi_lane1_en) ppi_bytes.push_back(item.ppi_data_lane1);
    if(item.ppi_lane2_en) ppi_bytes.push_back(item.ppi_data_lane2);
    if(item.ppi_lane3_en) ppi_bytes.push_back(item.ppi_data_lane3);

    // drop junk until we see the start marker
    while(ppi_bytes.size() > 0 && ppi_bytes[0] != START_BYTE)
      dropped_byte = ppi_bytes.pop_front();

    // wait until a full packet has arrived
    if(ppi_bytes.size() < PKT_LEN)
      return;

    repeat(6)           dropped_byte = ppi_bytes.pop_front();     // pop AA,FF,header(4)
    repeat(PAYLOAD_LEN) payload_bytes.push_back(ppi_bytes.pop_front()); // store payload
    repeat(4)           dropped_byte = ppi_bytes.pop_front();     // pop footer: crc,FF,BB

    // rebuild each pixel and compare
    pixel_count = payload_bytes.size() / 3;

    for(int i=0; i<pixel_count; i++) begin

      actual_pixel = {payload_bytes[i*3+2], payload_bytes[i*3+1], payload_bytes[i*3]};

      if(i >= expected_pixels.size()) begin
        `uvm_error("SBD",$sformatf("EXTRA PIXEL[%0d] = %06h",i,actual_pixel))
      end
      else if(actual_pixel === expected_pixels[i]) begin
        `uvm_info("SBD",$sformatf("PIXEL[%0d] PASS EXP=%06h ACT=%06h",i,expected_pixels[i],actual_pixel),UVM_MEDIUM)
      end
      else begin
        `uvm_error("SBD",$sformatf("PIXEL[%0d] FAIL EXP=%06h ACT=%06h",i,expected_pixels[i],actual_pixel))
      end

    end

    if(pixel_count != expected_pixels.size())
      `uvm_error("SBD",$sformatf("PIXEL COUNT MISMATCH EXP=%0d ACT=%0d",expected_pixels.size(),pixel_count));

  endfunction
endclass