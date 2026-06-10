// cnt_tb.sv
// basic tb for modulo-10 counter with validated load and async active low reset 

`timescale 1ns/1ps

module cnt_tb();

  // constants
  localparam WIDTH = 4;    // match DUT instantiation

  // default parameters
  int T       = 40;   // clock period             - (default)
  int tb_skew = 5;    // virtual-to-physical skew - (default)
  int tskew   = 3;    // probe skew (before end of physical clock) - (default)
  string tests[$];    // dynamic queue of test names to run

  // signals
  logic clk, rst_n, load;
  logic [WIDTH-1:0] data_in, count;

  // variables
  logic tb_clk; 
  integer vectornum=0, errors=0;
  integer log_fd;

  // instantiate device under test (DUT)
  // using SV wild card port association
  cnt #(.WIDTH(4)) dut(.*);

  // --------------------
  // read config.txt
  // --------------------
  task read_config;
    int    fd;
    string key;
    string sval;
    int    ret;

    fd = $fopen("./config.txt", "r");
    if (fd == 0) begin
        $display("INFO: config.txt not found, using defaults: T=%0d tb_skew=%0d tskew=%0d",
                  T, tb_skew, tskew);
        // tests.push_back("test_up_count");   // uncomment if you want to run a default test
        return;
    end

    // read line by line using $fgets then parse with $sscanf
    begin
        string line;
        while ($fgets(line, fd)) begin
            // skip blank lines and comment lines
            if (line.len() == 0)          continue;
            if (line.substr(0,0) == "#")  continue;
            if (line.substr(0,0) == "\n") continue;

            ret = $sscanf(line, "%s %s", key, sval);
            if (ret != 2)                 continue;
            if (key.substr(0,0) == "#")   continue;

            case (key)
                "T"       : T       = sval.atoi();
                "TB_SKEW" : tb_skew = sval.atoi();
                "TSKEW"   : tskew   = sval.atoi();
                "TEST"    : tests.push_back(sval);
            endcase
        end
    end

    $fclose(fd);
    $display("Config loaded: T=%0d tb_skew=%0d tskew=%0d", T, tb_skew, tskew);
    $display("Tests to run: %0d", tests.size());
    foreach (tests[i]) $display("  [%0d] %s", i, tests[i]);
  endtask

  // -------------------------
  // Test dispatcher
  // -------------------------
  task run_regressions;
    if (tests.size() == 0) begin
        $display("WARNING: no tests specified in config.txt");
        return;
    end
    foreach (tests[i]) begin
        $display("\n--- Running test [%0d/%0d]: %s ---\n",
                  i+1, tests.size(), tests[i]);
        case (tests[i])
            "test_up_count"     : test_up_count(20);
            "test_valid_load"   : test_valid_load(6);   // passing arguments: from 0 to 9
            "test_invalid_load" : test_invalid_load(0); // passing argument:  only 0
            default : $display("WARNING: unknown test '%s'", tests[i]);
        endcase
        wait_tb_clk(2);   // settling time between tests
    end
  endtask

  // output simulation in VCD format
  initial
  begin
    $display("\n");
    $dumpfile("waveforms.vcd");
    $dumpvars(0, cnt_tb);
  end

  // time format
  initial
    begin
      $timeformat(-9, 1, " ns", 10); // set time format to be ns
  end

  // generate free running virtual clock
  initial tb_clk = 0;  //  trick to avoid time-0 X.
  initial begin
    #1; // 1ns delay - to let read_config finish before clock starts
    forever #(T/2) tb_clk = ~tb_clk;
  end

  // System clock with transport delay (skew)
  always @(tb_clk) begin
    clk <= #(tb_skew) tb_clk;   // transport‑style delay
  end

  // wait tb_clk rising edge
  task wait_tb_clk(input int num_cyc = 1);
    repeat (num_cyc) begin
      @(posedge tb_clk);
    end
  endtask

  // wait tb_clk falling edge
  task wait_tb_fclk(input int num_cyc = 1);
    repeat (num_cyc) begin
      @(negedge tb_clk);
    end
  endtask

  // wait clk rising edge
  task wait_clk(input int num_cyc = 1);
    repeat (num_cyc) begin
      @(posedge clk);
    end
  endtask

  // A simple print message task
  task print_msg(string message);
    // Using $display to control output format
    $display("%0t: %s", $realtime, message);
    /* Alternative approach: use $fatal rather than $dislay to stop simulation with a specific exit code */
    /* $fatal(1, "%0t: %s", $realtime, message); */
  endtask

  // initialize tb
  task init_tb;
  begin
    data_in  = '0;
    rst_n    = 1'b1;
    load     = 1'b0;
  end
  endtask

  // apply async reset 
  task apply_reset;
    wait_tb_clk(1);
    rst_n = 1'b0;   // assert reset on rising edge of tb_clk
    wait_tb_fclk(1);
    rst_n = 1'b1;   // release reset on falling edge of tb_clk 
  endtask

  // apply power-on async reset 
  task reset_tb;
    rst_n = 1'b0;   // assert reset
    #2;             // hold it for 2 ns              
    rst_n = 1'b1;   // release reset 
  endtask

  // ----------------
  // test up-counting
  // ----------------
  task test_up_count(input int num_cyc = 10);
  int expected;
  int cycle;
  begin
    print_msg("up-count testing");

    apply_reset;   // start from known state (count = 0)
                   // at the end of apply_reset we are aligned 
                   // on the falling edge of tb_clk
    expected = 0;  // after reset count is 0

    for (cycle = 0; cycle < num_cyc; cycle++) begin
       @(posedge clk)
       expected = (expected + 1) % 10;  
       #(T - tskew);                     // probe close to end of clock cycle
       if (count !== expected) begin
          $display("ERROR [up-count]: expected=%0d got=%0d at time %0t",
                    expected, count, $realtime);
          errors++;
       end else begin
          $display("OK    [up-count] expected=%0d: count=%0d at time %0t",
                    expected, count, $realtime);
       end
       vectornum++;
    end
    // summary
    if (errors == 0)
      print_msg("up-count testing PASSED");
    else
      $display("up-count testing FAILED: %0d error(s) out of %0d vector(s)", 
                errors, vectornum);
  end
  endtask

  // ----------------
  // test valid load
  // ----------------
  task test_valid_load(input int expected = 7);
  begin
    errors    = 0;
    vectornum = 0;

    print_msg("valid load testing");

    // NOTE: data_in valid range is from 0 to 9

    wait_tb_clk(1); // align on rising edge of tb_clk
    load = 1'b1;
    data_in = expected;

    wait_tb_clk(1); 
    load    = 1'b0;    // deactivate load
    data_in = 'x;

    #(tb_skew - tskew);                     // probe close to end of clock cycle
    if (count !== expected) begin
      $display("ERROR [valid load]: expected=%0d got=%0d at time %0t",
                expected, count, $realtime);
      $display("NOTE: data_in valid range is from 0 to 9 inclusive"); 
      errors++;
    end else begin
      $display("OK    [valid load] expected=%0d, count=%0d at time %0t",
                expected, count, $realtime);
       end
    vectornum++;

    // summary
    if (errors == 0)
      print_msg("valid load testing PASSED");
    else
      $display("valid load testing FAILED: %0d error(s) out of %0d vector(s)", 
                errors, vectornum);

  end
  endtask

  // ----------------
  // test invalid load
  // ----------------
  task test_invalid_load(input int expected);
  begin
    errors    = 0;
    vectornum = 0;

    print_msg("invalid load testing");

    // NOTE: data_in valid range is from 0 to 9
    //       when the value of data_in is out of bound, the value of cnt is set to 0

    wait_tb_clk(1); // align on rising edge of tb_clk
    load = 1'b1;
    data_in = 13;   // assign an invalid data_in 

    wait_tb_clk(1); 
    load = 1'b0;    // deactivate load
    data_in = 'x;

    #(tb_skew - tskew);                     // probe close to end of clock cycle
    if (count !== expected) begin
      $display("ERROR [invalid load]: expected=%0d got=%0d at time %0t",
                expected, count, $realtime);
      $display("NOTE: when data_in is out of bound, count is set to 0"); 
      errors++;
    end else begin
      $display("OK    [invalid load] expected=%0d, count=%0d at time %0t",
                expected, count, $realtime);
       end
    vectornum++;


    // summary
    if (errors == 0)
      print_msg("invalid load testing PASSED");
    else
      $display("invalid load testing FAILED: %0d error(s) out of %0d vector(s)", 
                errors, vectornum);

  end
  endtask

  /******************
   * main testbench * 
   ******************/
  initial begin
    read_config;      //  must be first line so T and tb_skew are set
                      //  before anything else runs

    // create a log file
    log_fd = $fopen("logfile.sim", "w");
    if (log_fd == 0)
        $display("WARNING: could not open logfile.sim");

    $display("\nStart Testing: %0t \n",$realtime);
    $fdisplay(log_fd,"\nStart Testing: %0t \n",$realtime);

    init_tb;          // initialize the testbench
    reset_tb;         // power-on async reset

    wait_tb_clk(3);   // leave the simulator go for a few cycles 
                      // align on rising edge of tb_clk

    run_regressions;

    wait_tb_clk(2);   // leave everything as is for two cycles

    $display("\nEnd Testing: %0t \n",$realtime);
    $fdisplay(log_fd,"\nEnd Testing: %0t \n",$realtime);
    
    $display("Let the simulation stumble for a few extra cycles");
    data_in = 'x;
    load    = 1'bx;
    wait_tb_clk(2);
    print_msg("Ciao. Ich \"habe\" fertig! \n");
    $fdisplay(log_fd,"\nCiao. Ich \"habe\" fertig: %0t \n",$realtime);
    $fclose(log_fd);
    $finish;
  end

  // probe inputs at rising edge of physical clock cycle
  always @(posedge tb_clk) begin
      #(tb_skew); // tb_clk rising edge + #(tb_skew) = clk rising edge
      // $strobe("at time %9t: load = %b, data_in = %d", $time, load, data_in); //transcript
      $fstrobe(log_fd, "at time %9t: load = %b, data_in = %d", $time, load, data_in);   //log file
  end

  // probe output count close to end of physical clock cycle
  always @(posedge clk) begin
      #(T - tskew); 
      // $strobe("at time %9t: count = %d", $time, count); // transcript
      $fstrobe(log_fd, "at time %9t: count = %d", $time, count);   // log file
  end

endmodule
