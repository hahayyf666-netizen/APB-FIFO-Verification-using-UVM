
class fifo_reset_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_reset_sequence)

    function new(string name = "fifo_reset_sequence");
        super.new(name);
    endfunction : new

    task body();

        bit empty, full;
        bit almost_full, almost_empty;
        bit overflow, underflow;
        bit [7:0] count;

        `uvm_info("SEQ",
                 "============================================================",
                 UVM_MEDIUM)

        `uvm_info(get_type_name(),
                  "Starting Reset Sequence - Testing Reset Behavior",
                  UVM_MEDIUM)

        // --------------------------------------------------
        // Test 1: Initial hardware reset
        // --------------------------------------------------
        `uvm_info(get_type_name(),
                  "Test 1: Asserting hardware reset (PRESETn=0)",
                  UVM_MEDIUM)

        repeat (3) begin
            reset_fifo();
        end

        `uvm_info(get_type_name(),
                  "Reset held for 3 clock cycles",
                  UVM_MEDIUM)

        // Check FIFO status after reset
        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 0 || !empty || full ||
            overflow || underflow) begin

            `uvm_error("RESET_CHECK",
                $sformatf(
                    "Initial reset failed: expected count=0, empty=1, full=0, overflow=0, underflow=0; got count=%0d, empty=%0b, full=%0b, overflow=%0b, underflow=%0b",
                    count, empty, full, overflow, underflow))

        end else begin

            `uvm_info(get_type_name(),
                      "PASS: FIFO is empty after initial reset",
                      UVM_MEDIUM)

        end

        // --------------------------------------------------
        // Test 2: Push data before the second reset
        // --------------------------------------------------
        `uvm_info(get_type_name(),
                  "Test 2: Pushing data into FIFO",
                  UVM_MEDIUM)

        enable_fifo();

        push_data(8'h10);
        push_data(8'h11);
        push_data(8'h12);

        // Verify FIFO contains 3 entries
        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 3 || empty || full) begin

            `uvm_error("RESET_CHECK",
                $sformatf(
                    "Push failed: expected count=3, empty=0, full=0; got count=%0d, empty=%0b, full=%0b",
                    count, empty, full))

        end else begin

            `uvm_info(get_type_name(),
                      "PASS: FIFO contains 3 entries before second reset",
                      UVM_MEDIUM)

        end

        // --------------------------------------------------
        // Test 3: Reset FIFO while it contains data
        // --------------------------------------------------
        `uvm_info(get_type_name(),
                  "Test 3: Resetting FIFO while it contains 3 entries",
                  UVM_MEDIUM)

        repeat (3) begin
            reset_fifo();
        end

        `uvm_info(get_type_name(),
                  "Second reset held for 3 clock cycles",
                  UVM_MEDIUM)

        // Verify FIFO has been cleared
        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 0 || !empty || full ||
            overflow || underflow) begin

            `uvm_error("RESET_CHECK",
                $sformatf(
                    "Second reset failed: expected count=0, empty=1, full=0, overflow=0, underflow=0; got count=%0d, empty=%0b, full=%0b, overflow=%0b, underflow=%0b",
                    count, empty, full, overflow, underflow))

        end else begin

            `uvm_info(get_type_name(),
                      "PASS: FIFO cleared after second hardware reset",
                      UVM_MEDIUM)

        end

        // --------------------------------------------------
        // Test 4: Verify normal operation after reset release
        // --------------------------------------------------
        `uvm_info(get_type_name(),
                  "Test 4: Verifying FIFO recovery after reset",
                  UVM_MEDIUM)

        enable_fifo();

        push_data(8'h10);
        push_data(8'h20);
        push_data(8'h30);

        // Verify FIFO works normally after reset
        read_status(empty, full, almost_full, almost_empty,
                    overflow, underflow, count);

        if (count != 3 || empty || full) begin

            `uvm_error("RESET_CHECK",
                $sformatf(
                    "FIFO recovery failed: expected count=3, empty=0, full=0; got count=%0d, empty=%0b, full=%0b",
                    count, empty, full))

        end else begin

            `uvm_info(get_type_name(),
                      "PASS: FIFO recovered and accepted 3 entries after reset",
                      UVM_MEDIUM)

        end

        `uvm_info(get_type_name(),
                  "Reset Sequence Complete",
                  UVM_MEDIUM)

        `uvm_info("SEQ",
                  "============================================================",
                  UVM_MEDIUM)

    endtask : body

endclass : fifo_reset_sequence
