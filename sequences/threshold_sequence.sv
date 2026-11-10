class threshold_sequence extends apb_base_sequence;

    `uvm_object_utils(threshold_sequence)

    function new(string name = "threshold_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [31:0] status, thresh_read;
        bit almost_full, almost_empty;
        bit overflow, underflow;
        bit full, empty;
        bit [7:0] count;

        `uvm_info(get_type_name(), "Starting Threshold Sequence", UVM_MEDIUM)

        // Test 1: Set thresholds at start, fill FIFO and track flag transitions
        `uvm_info(get_type_name(), "TEST 1: Initial threshold setting and flag tracking", UVM_MEDIUM)
        
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)

        // Clear FIFO to guarantee a clean initial state
        clear_fifo();

        // Verify initial FIFO state
        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 0 || !empty || full) begin
                `uvm_error("THRESHOLD_CHECK",
                        $sformatf("FIFO initialization failed: expected count=0, empty=1, full=0; got count=%0d, empty=%0b, full=%0b",
                                          count, empty, full))
                end else begin
                    `uvm_info(get_type_name(),
                                  "PASS: FIFO initialized to empty state",
                                                UVM_MEDIUM)
                    end

        // Set thresholds: almost_full_th = 12, almost_empty_th = 4
        `uvm_info(get_type_name(), "Setting THRESH: almost_full=12, almost_empty=4", UVM_MEDIUM)
        write_reg(THRESH_OFFSET, {16'h0, 8'd4, 8'd12});
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH readback: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
        // Fill FIFO element by element and track almost_empty flag
        `uvm_info(get_type_name(), "Filling FIFO and tracking almost_empty flag (should clear at count > 4)", UVM_MEDIUM)
        for (int i = 0; i < 8; i++) begin
            push_data(8'hA0 + i);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
           if (count != (i + 1) || almost_full != 0 || almost_empty != ((i + 1) <= 4)) begin
               `uvm_error("THRESHOLD_CHECK", $sformatf("Push boundary mismatch: expected count=%0d, AF=0, AE=%0b; got count=%0d, AF=%0b, AE=%0b", i+1, ((i+1)<=4), count, almost_full, almost_empty))
               end
           `uvm_info(get_type_name(), $sformatf("After push %0d: count=%0d, almost_empty=%0b, almost_full=%0b",
                      i+1, count, almost_empty, almost_full), UVM_MEDIUM)
        end
        
        // Continue filling and track almost_full flag
        `uvm_info(get_type_name(), "Continuing fill and tracking almost_full flag (should set at count > 12)", UVM_MEDIUM)
        for (int i = 8; i < FIFO_DEPTH; i++) begin
            push_data(8'hA0 + i);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if ((count != (i + 1)) || (almost_full != ((i + 1) > 12)) || (almost_empty != 0) || (full != ((i + 1) == FIFO_DEPTH))) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Fill mismatch: expected count=%0d, AF=%0b, AE=0, FULL=%0b; got count=%0d, AF=%0b, AE=%0b, FULL=%0b", i+1, ((i+1)>12), ((i+1)==FIFO_DEPTH), count, almost_full, almost_empty, full))
end

            `uvm_info(get_type_name(), $sformatf("After push %0d: count=%0d, almost_empty=%0b, almost_full=%0b, full=%0b", 
                      i+1, count, almost_empty, almost_full, full), UVM_MEDIUM)
        end
        
        // Now pop and track flag transitions
        `uvm_info(get_type_name(), "Popping data and tracking almost_full flag (should clear at count <= 12)", UVM_MEDIUM)
        for (int i = 0; i < 6; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if ((count != (FIFO_DEPTH - i - 1)) || (almost_full != ((FIFO_DEPTH - i - 1) > 12)) || (almost_empty != 0) || (full != 0) || (empty != 0)) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Pop boundary mismatch: expected count=%0d, AF=%0b, AE=0, FULL=0, EMPTY=0; got count=%0d, AF=%0b, AE=%0b, FULL=%0b, EMPTY=%0b", FIFO_DEPTH-i-1, ((FIFO_DEPTH-i-1)>12), count, almost_full, almost_empty, full, empty))
end

            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_empty=%0b, almost_full=%0b", 
                      i+1, count, almost_empty, almost_full), UVM_MEDIUM)
        end
        
        // Continue popping and track almost_empty flag
        `uvm_info(get_type_name(), "Continuing pop and tracking almost_empty flag (should set at count <= 4)", UVM_MEDIUM)
        for (int i = 6; i < 14; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if ((count != (FIFO_DEPTH - i - 1)) || (almost_full != 0) || (almost_empty != ((FIFO_DEPTH - i - 1) <= 4)) || (full != 0) || (empty != 0)) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Pop boundary mismatch: expected count=%0d, AF=0, AE=%0b, FULL=0, EMPTY=0; got count=%0d, AF=%0b, AE=%0b, FULL=%0b, EMPTY=%0b", FIFO_DEPTH-i-1, ((FIFO_DEPTH-i-1)<=4), count, almost_full, almost_empty, full, empty))
end

            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_empty=%0b, almost_full=%0b, empty=%0b", 
                      i+1, count, almost_empty, almost_full, empty), UVM_MEDIUM)
        end

        //===========================================================================
        // Test 2: Clear FIFO and verify thresholds remain unchanged
        //===========================================================================
        `uvm_info(get_type_name(), "TEST 2: Clear FIFO and verify thresholds persistence", UVM_MEDIUM)
        
        // Push a few elements
        for (int i = 0; i < 5; i++) begin
            push_data(8'hB0 + i);
        end
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if (count != 7 || empty || full) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Before clear: expected count=7, empty=0, full=0; got count=%0d, empty=%0b, full=%0b", count, empty, full))
end else begin
`uvm_info(get_type_name(), "PASS: FIFO contains 7 entries before clear", UVM_MEDIUM)
end

        `uvm_info(get_type_name(), $sformatf("Before clear: count=%0d", count), UVM_MEDIUM)
        
        // Clear FIFO
        clear_fifo();
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if (count != 0 || !empty || full) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Clear failed: expected count=0, empty=1, full=0; got count=%0d, empty=%0b, full=%0b", count, empty, full))
end else begin
`uvm_info(get_type_name(), "PASS: FIFO cleared; count=0, empty=1, full=0", UVM_MEDIUM)
end

        `uvm_info(get_type_name(), $sformatf("After clear: count=%0d, empty=%0b", count, empty), UVM_MEDIUM)
        
        // Read thresholds - should be unchanged
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH after clear: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
        if (thresh_read[15:8] == 8'd4 && thresh_read[7:0] == 8'd12) begin
            `uvm_info(get_type_name(), "✓ Thresholds correctly preserved after clear", UVM_MEDIUM)
        end else begin
            `uvm_error("THRESHOLD_CHECK", "Thresholds changed after clear (unexpected!)")
        end

        //===========================================================================
        // Test 3: Update thresholds while FIFO contains elements
        //===========================================================================
        `uvm_info(get_type_name(), "TEST 3: Update thresholds with FIFO partially filled", UVM_MEDIUM)
        
        // Fill FIFO to 8 elements
        for (int i = 0; i < 8; i++) begin
            push_data(8'hC0 + i);
        end
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("FIFO has %0d elements, almost_full=%0b, almost_empty=%0b", 
                  count, almost_full, almost_empty), UVM_MEDIUM)
        
        // Change thresholds: almost_full_th = 6, almost_empty_th = 10
        `uvm_info(get_type_name(), "Updating THRESH to: almost_full=6, almost_empty=10", UVM_MEDIUM)
        write_reg(THRESH_OFFSET, {16'h0, 8'd10, 8'd6});
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH updated: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
                // Check status after threshold write and THRESH readback
        `uvm_info(get_type_name(),
                  "Checking threshold flags after write and readback",
                  UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        `uvm_info(get_type_name(),
                  $sformatf("Status: count=%0d, AF=%0b, AE=%0b",
                            count, almost_full, almost_empty),
                  UVM_MEDIUM)

        if (count != 8 || !almost_full || !almost_empty) begin

            `uvm_error("THRESHOLD_CHECK",
                $sformatf("Expected count=8, AF=1, AE=1; got count=%0d, AF=%0b, AE=%0b",
                          count, almost_full, almost_empty))

            // Diagnostic read after additional delay
            `uvm_info(get_type_name(),
                      "Checking flags again after additional delay",
                      UVM_MEDIUM)

            #10;

            read_status(empty, full, almost_full, almost_empty,
                        overflow, underflow, count);

            `uvm_info(get_type_name(),
                      $sformatf("Delayed read: count=%0d, AF=%0b, AE=%0b",
                                count, almost_full, almost_empty),
                      UVM_MEDIUM)

            if (count == 8 && almost_full && almost_empty) begin
                `uvm_info(get_type_name(),
                          "Flags match expected values after additional delay; investigate update latency",
                          UVM_MEDIUM)
            end

        end else begin

            `uvm_info(get_type_name(),
                      "PASS: COUNT=8, AF=1, AE=1",
                      UVM_MEDIUM)

        end

        `uvm_info(get_type_name(),
                  "===============================================",
                  UVM_MEDIUM)

        // Push 3 more elements to exceed almost_empty threshold
        `uvm_info(get_type_name(),
                  "Pushing 3 more elements, expected count=11",
                  UVM_MEDIUM)

        for (int i = 0; i < 3; i++) begin
            push_data(8'hD0 + i);
        end

        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 11 || !almost_full || almost_empty) begin
            `uvm_error("THRESHOLD_CHECK",
                $sformatf("Expected count=11, AF=1, AE=0; got count=%0d, AF=%0b, AE=%0b",
                          count, almost_full, almost_empty))
        end else begin
            `uvm_info(get_type_name(),
                      "PASS: COUNT=11, AF=1, AE=0",
                      UVM_MEDIUM)
        end
        // Pop to test threshold behavior
        `uvm_info(get_type_name(), "Popping elements to test threshold crossings", UVM_MEDIUM)
        for (int i = 0; i < 6; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
if ((count != (10 - i)) || (almost_full != ((10 - i) > 6)) || (almost_empty != 1) || (full != 0) || (empty != 0)) begin
`uvm_error("THRESHOLD_CHECK", $sformatf("Dynamic pop mismatch: expected count=%0d, AF=%0b, AE=1, FULL=0, EMPTY=0; got count=%0d, AF=%0b, AE=%0b, FULL=%0b, EMPTY=%0b", 10-i, ((10-i)>6), count, almost_full, almost_empty, full, empty))
end

            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_full=%0b, almost_empty=%0b", 
                      i+1, count, almost_full, almost_empty), UVM_MEDIUM)
        end

        // Clean up
        clear_fifo();
        
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Threshold Sequence Complete", UVM_MEDIUM)
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
    endtask : body

endclass : threshold_sequence
