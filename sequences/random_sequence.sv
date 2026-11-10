class random_sequence extends apb_base_sequence;
  
  `uvm_object_utils(random_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[50:200]};
  }
  
  function new(string name = "random_sequence");
    super.new(name);
  endfunction : new
  
task body();
apb_sequence_item item;
apb_sequence_item rsp;

`uvm_info("SEQ", $sformatf("Starting Random Sequence with %0d transactions", num_transactions), UVM_MEDIUM)

// Enable FIFO first
enable_fifo();

// Create one item and reuse it to preserve randc state
item = apb_sequence_item::type_id::create("item");

for (int i = 0; i < num_transactions; i++) begin

start_item(item);

// Clear previous response fields
item.prdata = '0;
item.pslverr = 1'b0;

// Randomize transaction
if (!item.randomize() with {
(paddr == STATUS_OFFSET) -> (pwrite == 1'b0);
}) begin
`uvm_fatal("SEQ", "Randomization failed; refusing to send invalid item")
end

finish_item(item);

// Consume driver response
get_response(rsp);

`uvm_info("SEQ", $sformatf("Transaction %0d: PRESETn=%0b PADDR=0x%02h PWRITE=%0b PWDATA=0x%08h PRDATA=0x%08h PSLVERR=%0b", i, rsp.presetn, rsp.paddr, rsp.pwrite, rsp.pwdata, rsp.prdata, rsp.pslverr), UVM_HIGH)

end

`uvm_info("SEQ", "Random Sequence Complete", UVM_MEDIUM)

endtask : body
  
endclass : random_sequence
