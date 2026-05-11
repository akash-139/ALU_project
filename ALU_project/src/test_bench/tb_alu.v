module tb_alu;
  parameter width = 8, cmd_width = 4;

  reg clk, rst, mode, ce, cin;
  reg [1:0] inp_valid;
  reg [cmd_width-1:0] cmd;
  reg [width-1:0] opa, opb;

  wire [(2*width)-1:0] res;
  wire oflow, cout, g, l, e, err;

  reg [width-1:0] t_a, t_b;
  reg [3:0] t_c,t_inp;
  reg t_cin;
  reg t_m;
  reg [2*width-1:0] hold_res;
  reg hold_of, hold_co, hold_g, hold_l, hold_e, hold_err;

  alu dut(.CLK(clk),.RST(rst),.MODE(mode),.CE(ce),.INP_VALID(inp_valid),.CMD(cmd),.OPA(opa),.OPB(opb),.CIN(cin),.RES(res),.OFLOW(oflow),.COUT(cout),.G(g),.L(l),.E(e),.ERR(err));

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic alu_ref;
    input mode;
    input [1:0] inp_valid;
    input [cmd_width-1:0] cmd;
    input [width-1:0] opa, opb;
    input cin;
    output [2*width-1 : 0] res;
    output oflow, cout, g, l, e, err;
    begin
      res = 0; oflow = 0; cout = 0;
      g = 0; l = 0; e = 0; err = 0;
      if(mode) begin
        case(cmd)
          0: begin
            if(inp_valid == 2'b11) begin
                res = opa + opb;
                cout = ({1'b0,opa} + {1'b0,opb}) >> width;
            end
            else err = 1'b1;
          end
          1: begin
            if(inp_valid == 2'b11) begin
                res = opa - opb;
                oflow = opa < opb;
            end
            else err = 1'b1;
          end
          2: begin
            if(inp_valid == 2'b11 ) begin
                res = opa + opb + cin;
                cout = ({1'b0,opa} + {1'b0,opb} + cin) >> width;
            end
            else err = 1'b1;
          end
          3: begin
            if(inp_valid == 2'b11) begin
                res = opa - opb - cin;
              oflow = opa < {1'b0,opb}+cin;
            end
            else err = 1'b1;
          end
          4: begin
            if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = opa + 1;
            else err = 1'b1;
          end
          5: begin
            if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = opa - 1;
            else err = 1'b1;
          end
          6: begin
            if((inp_valid == 2'b11 || inp_valid == 2'b10)) res = opb + 1;
            else err = 1'b1;
          end
          7: begin
            if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = opb - 1;
            else err = 1'b1;
          end
          8: begin
            if(inp_valid == 2'b11) begin
              if(opa > opb) g = 1;
              else if(opa < opb) l = 1;
              else e = 1;
            end
            else err = 1'b1;
          end
          9: begin
            if(inp_valid == 2'b11) res = (opa+1) * (opb+1);
            else err = 1;
          end
          10: begin
            if(inp_valid == 2'b11) res = (opa<<1) * (opb);
            else err = 1;
          end
          11: begin
            if(inp_valid == 2'b11) begin
              if($signed(opa) > $signed(opb)) g = 1;
              else if($signed(opa) < $signed(opb)) l = 1;
              else e = 1;
              res = $signed(opa) + $signed(opb);
              oflow = (opa[width-1] == opb[width-1]) && ((((opa + opb) >> (width-1)) & 1'b1) != opa[width-1]);
            end
            else err = 1'b1;
          end
          12: begin
            if(inp_valid == 2'b11) begin
              if($signed(opa) > $signed(opb)) g = 1;
              else if($signed(opa) < $signed(opb)) l = 1;
              else e = 1;
              res = $signed(opa) - $signed(opb);
              oflow = (opa[width-1] != opb[width-1]) && ((((opa - opb) >> (width-1)) & 1'b1) != opa[width-1]);
            end
            else err = 1'b1;
          end
          default: begin res = 0; oflow = 0; cout = 0; g = 0; e = 0; l = 0; end
        endcase
      end
      else begin
        case(cmd)
          0: if(inp_valid == 2'b11) res = opa & opb; else err = 1'b1;
          1: if(inp_valid == 2'b11) res = ~(opa & opb); else err = 1'b1;
          2: if(inp_valid == 2'b11) res = opa | opb; else err = 1'b1;
          3: if(inp_valid == 2'b11) res = ~(opa | opb); else err = 1'b1;
          4: if(inp_valid == 2'b11) res = opa ^ opb; else err = 1'b1;
          5: if(inp_valid == 2'b11) res = ~(opa ^ opb); else err = 1'b1;
          6: if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = ~opa; else err = 1'b1;
          7: if((inp_valid == 2'b11 || inp_valid == 2'b10)) res = ~opb; else err = 1'b1;
          8: if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = opa>>1; else err = 1'b1;
          9: if((inp_valid == 2'b11 || inp_valid == 2'b01)) res = opa<<1; else err = 1'b1;
          10: if((inp_valid == 2'b11 || inp_valid == 2'b10)) res = opb>>1; else err = 1'b1;
          11: if((inp_valid == 2'b11 || inp_valid == 2'b10)) res = opb<<1; else err = 1'b1;
          12: if(inp_valid == 2'b11) begin
              if(opb[7:4] != 0) err = 1;
              case(opb[2:0])
                0: res = opa;
                1: res = {opa[width-2:0], opa[width-1]};
                2: res = {opa[width-3:0], opa[width-1:width-2]};
                3: res = {opa[width-4:0], opa[width-1:width-3]};
                4: res = {opa[width-5:0], opa[width-1:width-4]};
                5: res = {opa[width-6:0], opa[width-1:width-5]};
                6: res = {opa[width-7:0], opa[width-1:width-6]};
                7: res = {opa[width-8:0], opa[width-1:width-7]};
              endcase
            end
            else err = 1'b1;
          13: if(inp_valid == 2'b11) begin
              if(opb[7:4] != 0) err = 1;
              case(opb[2:0])
                0: res = opa;
                1: res = {opa[0], opa[width-1:1]};
                2: res = {opa[1:0], opa[width-1:2]};
                3: res = {opa[2:0], opa[width-1:3]};
                4: res = {opa[3:0], opa[width-1:4]};
                5: res = {opa[4:0], opa[width-1:5]};
                6: res = {opa[5:0], opa[width-1:6]};
                7: res = {opa[6:0], opa[width-1:7]};
              endcase
            end
            else err = 1'b1;
        endcase
      end
    end
  endtask

  task automatic alu_driver;
    input d_mode; input [1:0] d_valid; input [cmd_width-1:0] d_cmd;
    input [width-1:0] d_opa, d_opb; input d_cin;
    begin
      @(negedge clk);
      mode = d_mode; inp_valid = d_valid; cmd = d_cmd;
      opa = d_opa; opb = d_opb; cin = d_cin; ce = 1'b1;
      if(d_mode == 1 && (d_cmd == 9 || d_cmd == 10)) repeat(4) @(posedge clk);
      else repeat(2) @(posedge clk);
      #1; ce = 1'b0;
    end
  endtask

  task automatic alu_monitor;
    input [2*width-1 : 0]exp_res;
    input exp_oflow,exp_cout,exp_g,exp_l,exp_e,exp_err;
    begin
      if(res === exp_res) $display("RES correct");
      else $display("RES incorrect: Got %h, Exp %h", res, exp_res);

      if(oflow === exp_oflow) $display("OFLOW correct");
      else $display("OFLOW incorrect");

      if(cout === exp_cout) $display("COUT correct");
      else $display("COUT incorrect");

      if(g === exp_g) $display("G correct");
      else $display("G incorrect");

      if(l === exp_l) $display("L correct");
      else $display("L incorrect");

      if(e === exp_e) $display("E correct");
      else $display("E incorrect");

      if(err === exp_err) $display("ERR correct");
      else $display("ERR incorrect");
    end
  endtask




  initial begin
    rst = 1; ce = 0; #20; rst = 0;
    repeat(20) begin
      t_a = $urandom; t_b = $urandom; t_c = $urandom; t_m = $urandom; t_inp = $urandom;t_cin = $urandom;
      alu_ref(t_m, t_inp, t_c, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_driver(t_m, t_inp, t_c, t_a, t_b, t_cin);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_ref(1, 2'b11, 0, 8'h7F, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h7F, 8'h01, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_driver(1, 2'b11, 0, 8'h70, 8'h70, 0);
    alu_driver(1, 2'b11, 0, 8'h80, 8'h80, 0);
    alu_driver(1, 2'b11, 0, 8'h80, 8'hFF, 0);
    alu_driver(1, 2'b11, 0, 8'h7F, 8'h01, 0);
    alu_driver(1, 2'b11, 0, 8'h01, 8'hFF, 0);
    alu_driver(1, 2'b11, 0, 8'h7F, 8'h01, 0);
    alu_driver(1, 2'b11, 0, 8'h80, 8'hFF, 0);
    alu_driver(1, 2'b11, 0, 8'h80, 8'h01, 0);

    alu_ref(1, 2'b11, 0, 8'h7F, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h7F, 8'h01, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h80, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h80, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h80, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h80, 8'h01, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h00, 8'hF0, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h00, 8'hF0, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b10, 9, 8'hAA, 8'h55, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b10, 9, 8'hAA, 8'h55, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h70, 8'h70, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h70, 8'h70, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h80, 8'h80, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h80, 8'h80, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'hFF, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'hFF, 8'h01, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 9, 8'hFE, 8'hFE, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'hFE, 8'hFE, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h80, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h80, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 0, 8'h80, 8'h80, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 0, 8'h80, 8'h80, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 9, 8'hFE, 8'hFE, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'hFE, 8'hFE, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 10, 8'h7F, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 10, 8'h7F, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_ref(1, 2'b11, 9, 8'h00, 8'hF0, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'h00, 8'hF0, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_ref(1, 2'b11, 9, 8'hFE, 8'hFE, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'hFE, 8'hFE, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 10, 8'h7F, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 10, 8'h7F, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b10, 9, 8'hAA, 8'h55, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b10, 9, 8'hAA, 8'h55, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b00, 9, 8'h00, 8'h00, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b00, 9, 8'h00, 8'h00, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_driver(1, 2'b11, 9, 8'h01, 8'h01, 0);
    alu_monitor(0, 0, 0, 1'b1, 1'b1, 1'b1, 1);

      alu_ref(1, 2'b10, 9, 8'hFF, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b10, 9, 8'hFF, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b10, 10, 8'hFF, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b10, 10, 8'hFF, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b00, 9, 8'h00, 8'h00, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b00, 9, 8'h00, 8'h00, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

     alu_ref(1, 2'b11, 9, 8'hFE, 8'hFE, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'hFE, 8'hFE, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 9, 8'h00, 8'h00, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 9, 8'h00, 8'h00, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 10, 8'h7F, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 10, 8'h7F, 8'hFF, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    alu_ref(1, 2'b11, 10, 8'h00, 8'h00, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
    alu_driver(1, 2'b11, 10, 8'h00, 8'h00, 0);
    alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      begin
      ce = 1;

      alu_driver(1, 2'b11, 4'd9, 8'h00, 8'h00, 0); repeat(10) @(posedge clk);
      alu_ref(1, 2'b11, 4'd9, 8'h00, 8'h00, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(1, 2'b11, 4'd9, 8'hFF, 8'hFF, 0); repeat(10) @(posedge clk);
      alu_ref(1, 2'b11, 4'd9, 8'hFF, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      end

      alu_driver(t_m, 2'b01, t_c, t_a, t_b, 0); repeat(3) @(posedge clk);
      alu_ref(1, 2'b01, t_c, t_a, t_b, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(0, 2'b11, 12, 8'hAA, 8'hF0, 0); repeat(3) @(posedge clk);
      alu_ref(0, 2'b11, 12, 8'hAA, 8'hF0, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(1, 2'b11, 15, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
      alu_ref(1, 2'b11, 15, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(1, 2'b11, 11, 8'h7F, 8'h01, 0); repeat(3) @(posedge clk);
      alu_ref(1, 2'b11, 11, 8'h7F, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(0, 2'b11, 3, 8'hFF, 8'hFF, 0); repeat(3) @(posedge clk);
      alu_ref(0, 2'b11, 3, 8'hFF, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(1, 2'b11, 0, 8'hFF, 8'hFF, 0); rst = 1; #10; rst = 0; repeat(3) @(posedge clk);
      alu_ref(1, 2'b11, 0, 8'hFF, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_driver(1, 2'b11, 11, 8'h80, 8'hFF, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'h80, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 11, 8'h40, 8'h40, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'h40, 8'h40, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(0, 2'b11, 12, 8'h55, 8'h08, 0); repeat(3) @(posedge clk);
alu_ref(0, 2'b11, 12, 8'h55, 8'h08, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(0, 2'b11, 13, 8'hAA, 8'h0F, 0); repeat(3) @(posedge clk);
alu_ref(0, 2'b11, 13, 8'hAA, 8'h0F, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b00, 5, 8'h12, 8'h34, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b00, 5, 8'h12, 8'h34, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(0, 2'b10, 2, 8'h00, 8'hFF, 0); repeat(3) @(posedge clk);
alu_ref(0, 2'b10, 2, 8'h00, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_driver(1, 2'b11, 11, 8'h7F, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'h7F, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 11, 8'h80, 8'hFF, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'h80, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 11, 8'h7F, 8'h80, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'h7F, 8'h80, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 12, 8'h80, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 12, 8'h80, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 12, 8'h7F, 8'hFF, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 12, 8'h7F, 8'hFF, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_driver(1, 2'b11, 0, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 0, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 1, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 1, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 6, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 6, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 7, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 7, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 9, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 9, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 10, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 10, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b00, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b00, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b01, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b01, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b10, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b10, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 2, 8'hFF, 8'h05, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 2, 8'hFF, 8'h05, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 11, 8'hFF, 8'hFF, 1); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 11, 8'hFF, 8'hFF, 1, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 12, 8'hFF, 8'hFF, 1); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 12, 8'hFF, 8'hFF, 1, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b01, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b01, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b10, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b10, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b00, 2, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b00, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 0, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 0, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 1, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 1, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 7, 8'h01, 8'h01, 0); repeat(3) @(posedge clk);
alu_ref(1, 2'b11, 7, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 2, 8'h01, 8'h01, 0); repeat(1) @(posedge clk);
alu_ref(1, 2'b11, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

alu_driver(1, 2'b11, 2, 8'h01, 8'h01, 0); repeat(5) @(posedge clk);
alu_ref(1, 2'b11, 2, 8'h01, 8'h01, 0, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);


      alu_driver(t_m, 2'b11, 0, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b11, 0, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_driver(t_m, 2'b11, 1, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b11, 1, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_driver(t_m, 2'b11, 7, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b11, 7, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(t_m, 2'b00, t_c, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b00, t_c, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);


      alu_driver(t_m, 2'b01, t_c, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b01, t_c, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(t_m, 2'b10, t_c, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b10, t_c, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

      alu_driver(t_m, 2'b11, t_c, t_a, t_b, t_cin); repeat(200) @(posedge clk);
      alu_ref(t_m, 2'b11, t_c, t_a, t_b, t_cin, hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);
      alu_monitor(hold_res, hold_of, hold_co, hold_g, hold_l, hold_e, hold_err);

    end
    #50; $finish;
  end
endmodule
