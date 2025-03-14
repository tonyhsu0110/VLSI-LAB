
`include "GATE_LIB.v"

module MAC6 (//input
             A,
             B,
             MODE,
assign B_extend = {{7{B[5]}}, B[5:0]};
assign ACC_extend = {ACC[11], ACC[11:0]};

wire [12:0] ACC_new, B_new;
wire [11:0] CARRY_from_Tree;
wire [12:0] SUM_from_Tree;
wire [12:0] CARRY_0, CARRY_1, SUM_0, SUM_1, RES_0, RES_1;

REV_13bit  X_REV_0 (.SEL(MODE[0]), .IN(ACC_extend), .OUT(ACC_new));
REV_13bit  X_REV_1 (.SEL(MODE[0]), .IN(B_extend),   .OUT(B_new));
MUL        X_MUL_0 (.S0(MODE[0]), .INA(A), .INB(B), .CARRY(CARRY_from_Tree), .SUM(SUM_from_Tree));
CSA_2      X_CSA_2 (.A(SUM_from_Tree), .B(CARRY_from_Tree), .C(ACC_new), .CARRY(CARRY_0), .SUM(SUM_0));
CSA_3      X_CSA_3 (.S0(MODE[0]), .A(A_extend), .B(B_new), .CARRY(CARRY_1), .SUM(SUM_1));

FA_CLA     X_FA_0  (.INA(SUM_0), .INB(CARRY_0), .CIN(1'b0), .RESULT(RES_0));
FA_CLA     X_FA_1  (.INA(SUM_1), .INB(CARRY_1), .CIN(1'b0), .RESULT(RES_1));
MUX_2X1    X_MUX   (.SEL(MODE[1]), .DATA0(RES_0), .DATA1(RES_1), .OUT(OUT));

endmodule

///////////////////////////////////////////////
//                 Multiplier                //
///////////////////////////////////////////////
module MUL (S0, INA, INB, CARRY, SUM);
	input S0;
	input [5:0] INA, INB;
	output [11:0] CARRY;
	output [12:0] SUM;
	
	wire [11:0] PP_0;
	wire [9:0] PP_1;
	wire [7:0] PP_2;
	
	MUL_output_term  X_MUL_term  (.INA(INA), .INB(INB), .PP_0(PP_0), .PP_1(PP_1), .PP_2(PP_2), .EXTRA0(EXTRA0), .EXTRA1(EXTRA1), .EXTRA2(EXTRA2));
	Wal_Tree    X_Wallace_Tree   (.S0(S0), .PP_term0(PP_0), .PP_term1(PP_1), .PP_term2(PP_2), .EXTRA_0(EXTRA0), .EXTRA_1(EXTRA1), .EXTRA_2(EXTRA2), .CARRY(CARRY), .SUM(SUM));
	
endmodule

module MUL_output_term (INA, INB, PP_0, PP_1, PP_2, EXTRA0, EXTRA1, EXTRA2);
	input  [5:0] INA, INB;
	output [11:0] PP_0;
	output [9:0] PP_1;
	output [7:0] PP_2;
	output EXTRA0, EXTRA1, EXTRA2;
	
	PP_Term0 X_PP_0 (.IN_A(INA), .IN_B(INB[1:0]), .PP_OUT(PP_0), .EXTRA(EXTRA0));
	PP_Term1 X_PP_1 (.IN_A(INA), .IN_B(INB[3:1]), .PP_OUT(PP_1), .EXTRA(EXTRA1));
	PP_Term2 X_PP_2 (.IN_A(INA), .IN_B(INB[5:3]), .PP_OUT(PP_2), .EXTRA(EXTRA2));
	
endmodule

///////////////////////////////////////////////
//               Booth Encoder               //
///////////////////////////////////////////////
module BE (LEFT, MID, RIGHT, SINGLE, DOUBLE, NEG);
	input  LEFT, MID, RIGHT;
	output SINGLE, DOUBLE, NEG;
	
	assign NEG = LEFT;
	VLSI_XOR2 X1 (.INA(RIGHT), .INB(MID), .OUT(SINGLE));
	VLSI_XNOR2 X2 (.INA(MID), .INB(LEFT), .OUT(N1));
	VLSI_NOR2 X3 (.INA(SINGLE), .INB(N1), .OUT(DOUBLE));
	
endmodule

///////////////////////////////////////////////
//              Partial Product              //
///////////////////////////////////////////////
module PP_Construct (IN_DATA, IN_DATA_R, SINGLE, DOUBLE, NEG, OUT);
	input  IN_DATA, IN_DATA_R, SINGLE, DOUBLE, NEG;
	output OUT;
	
	wire N1, N2, N3;
	
	VLSI_NAND2 X1 (.INA(IN_DATA), .INB(SINGLE), .OUT(N1));
	VLSI_NAND2 X2 (.INA(IN_DATA_R), .INB(DOUBLE), .OUT(N2));
	VLSI_NAND2 X3 (.INA(N1), .INB(N2), .OUT(N3));
	VLSI_XOR2  X4 (.INA(N3), .INB(NEG), .OUT(OUT));
	
endmodule


///////////////////////////////////////////////
//     Booth Encoder + Partial Product       //
///////////////////////////////////////////////
module PP_Term0 (IN_A, IN_B, PP_OUT, EXTRA);
	input  [5:0] IN_A;
	input  [1:0] IN_B;
	output [11:0] PP_OUT;
	output EXTRA;
	
	BE BE_0 (.LEFT(IN_B[1]), .MID(IN_B[0]), .RIGHT(1'b0), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG));
	
	VLSI_NOT NOT_FOR_EXTRA (.IN(NEG), .OUT(_NEG));
	
	PP_Construct PP0 (.IN_DATA(IN_A[0]), .IN_DATA_R(1'b0),    .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[0]));
	PP_Construct PP1 (.IN_DATA(IN_A[1]), .IN_DATA_R(IN_A[0]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[1]));
	PP_Construct PP2 (.IN_DATA(IN_A[2]), .IN_DATA_R(IN_A[1]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[2]));
	PP_Construct PP3 (.IN_DATA(IN_A[3]), .IN_DATA_R(IN_A[2]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[3]));
	PP_Construct PP4 (.IN_DATA(IN_A[4]), .IN_DATA_R(IN_A[3]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[4]));
	PP_Construct PP5 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[4]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[5]));
	PP_Construct PP6 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[5]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[6]));
	
	//VLSI_XNOR2  X_XOR (.INA(NEG), .INB(IN_A[5]), .OUT(L1));
	//VLSI_NOT   X_NOT (.IN(L1), .OUT(_L1));
	//assign PP_OUT[9:7] = {_L1, L1, L1};
	
	// VLSI_NOT   X_NOT (.IN(PP_OUT[6]), .OUT(_L1));
	// assign PP_OUT[9:7] = {_L1, PP_OUT[6], PP_OUT[6]};
	
	assign PP_OUT[11:7] = {{5{PP_OUT[6]}}};
	
	assign EXTRA = NEG;
	
endmodule

module PP_Term1 (IN_A, IN_B, PP_OUT, EXTRA);
	input  [5:0] IN_A;
	input  [2:0] IN_B;
	output [9:0] PP_OUT;
	output EXTRA;
	
	BE BE_0 (.LEFT(IN_B[2]), .MID(IN_B[1]), .RIGHT(IN_B[0]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG));
	
	VLSI_NOT NOT_FOR_EXTRA (.IN(NEG), .OUT(_NEG));
	
	PP_Construct PP0 (.IN_DATA(IN_A[0]), .IN_DATA_R(1'b0),    .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[0]));
	PP_Construct PP1 (.IN_DATA(IN_A[1]), .IN_DATA_R(IN_A[0]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[1]));
	PP_Construct PP2 (.IN_DATA(IN_A[2]), .IN_DATA_R(IN_A[1]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[2]));
	PP_Construct PP3 (.IN_DATA(IN_A[3]), .IN_DATA_R(IN_A[2]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[3]));
	PP_Construct PP4 (.IN_DATA(IN_A[4]), .IN_DATA_R(IN_A[3]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[4]));
	PP_Construct PP5 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[4]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[5]));
	PP_Construct PP6 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[5]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[6]));
	// VLSI_XOR2 X_XNOR(.INA(NEG), .INB(IN_A[5]), .OUT(PP_OUT[7]));
	// assign PP_OUT[8] = 1'b1;
	
	// VLSI_NOT   X_NOT (.IN(PP_OUT[6]), .OUT(_L1));
	// assign PP_OUT[7] = _L1;
	// assign PP_OUT[8] = 1'b1;
	
	assign PP_OUT[9:7] = {{3{PP_OUT[6]}}};
	
	assign EXTRA = NEG;
	
endmodule

module PP_Term2 (IN_A, IN_B, PP_OUT, EXTRA);
	input  [5:0] IN_A;
	input  [2:0] IN_B;
	output [7:0] PP_OUT;
	output EXTRA;
	
	BE BE_0 (.LEFT(IN_B[2]), .MID(IN_B[1]), .RIGHT(IN_B[0]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG));
	
	VLSI_NOT NOT_FOR_EXTRA (.IN(NEG), .OUT(_NEG));
	
	PP_Construct PP0 (.IN_DATA(IN_A[0]), .IN_DATA_R(1'b0),    .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[0]));
	PP_Construct PP1 (.IN_DATA(IN_A[1]), .IN_DATA_R(IN_A[0]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[1]));
	PP_Construct PP2 (.IN_DATA(IN_A[2]), .IN_DATA_R(IN_A[1]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[2]));
	PP_Construct PP3 (.IN_DATA(IN_A[3]), .IN_DATA_R(IN_A[2]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[3]));
	PP_Construct PP4 (.IN_DATA(IN_A[4]), .IN_DATA_R(IN_A[3]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[4]));
	PP_Construct PP5 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[4]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[5]));
	PP_Construct PP6 (.IN_DATA(IN_A[5]), .IN_DATA_R(IN_A[5]), .SINGLE(SINGLE), .DOUBLE(DOUBLE), .NEG(NEG), .OUT(PP_OUT[6]));
	// VLSI_XOR2 X_XNOR(.INA(NEG), .INB(IN_A[5]), .OUT(PP_OUT[7]));
	
	// VLSI_NOT   X_NOT (.IN(PP_OUT[6]), .OUT(_L1));
	// assign PP_OUT[7] = _L1;
	
	assign PP_OUT[7] = PP_OUT[6];
	
	assign EXTRA = NEG;
	
endmodule

///////////////////////////////////////////////
//              Wallace Tree                 //
///////////////////////////////////////////////
module Wal_Tree (S0, PP_term0, PP_term1, PP_term2, EXTRA_0, EXTRA_1, EXTRA_2, CARRY, SUM);
	input S0;
	input [11:0] PP_term0;
	input [9:0] PP_term1;
	input [7:0] PP_term2;
	input EXTRA_0, EXTRA_1, EXTRA_2;
	output [11:0] CARRY;
	output [12:0] SUM;
	
	wire [10:0] CARRY_0;
	wire [11:0] SUM_0;
	
	CSA_0  X_CSA_0  (.S0(S0), .A(PP_term1), .B(PP_term2), .EXTRA_0(EXTRA_0), .EXTRA_1(EXTRA_1), .EXTRA_2(EXTRA_2), .CARRY(CARRY_0), .SUM(SUM_0));
	CSA_1  X_CSA_1  (.A(PP_term0), .B(SUM_0), .C(CARRY_0), .CARRY(CARRY), .SUM(SUM));

endmodule


///////////////////////////////////////////////
//            Carry Save Adder               //
///////////////////////////////////////////////
module CSA_0 (S0, A, B, EXTRA_0, EXTRA_1, EXTRA_2, CARRY, SUM);
    input [9:0] A;
	input [7:0] B;
	input S0, EXTRA_0, EXTRA_1, EXTRA_2;
    output [10:0] CARRY;
	output [11:0] SUM;
	
    // HA HA_0 (.A(EXTRA_0), .B(S0),   .COUT(CARRY[0]), .SUM(SUM[0]));
	// assign SUM[1] = 1'b0;
	// assign CARRY[1] = 1'b0;
    // HA HA_1 (.A(A[0]), .B(EXTRA_1), .COUT(CARRY[2]), .SUM(SUM[2]));
    // HA HA_2 (.A(A[1]), .B(1'b0),    .COUT(CARRY[3]), .SUM(SUM[3]));
	// FA FA_only (.A(A[2]), .B(B[0]), .CIN(EXTRA_2),   .COUT(CARRY[4]), .SUM(SUM[4]));
    // HA HA_3 (.A(A[3]), .B(B[1]),    .COUT(CARRY[5]), .SUM(SUM[5]));
    // HA HA_4 (.A(A[4]), .B(B[2]),    .COUT(CARRY[6]), .SUM(SUM[6]));
    // HA HA_5 (.A(A[5]), .B(B[3]),    .COUT(CARRY[7]), .SUM(SUM[7]));
    // HA HA_6 (.A(A[6]), .B(B[4]),    .COUT(CARRY[8]), .SUM(SUM[8]));
    // HA HA_7 (.A(A[7]), .B(B[5]),    .COUT(CARRY[9]), .SUM(SUM[9]));
    // HA HA_8 (.A(A[8]), .B(B[6]),    .COUT(CARRY[10]),.SUM(SUM[10]));
	// assign SUM[11] = B[7];
	
	HA HA_0 (.A(EXTRA_0), .B(S0),   .COUT(CARRY[0]), .SUM(SUM[0]));
	assign SUM[1] = 1'b0;
	assign CARRY[1] = 1'b0;
    HA HA_1 (.A(A[0]), .B(EXTRA_1), .COUT(CARRY[2]), .SUM(SUM[2]));
    HA HA_2 (.A(A[1]), .B(1'b0),    .COUT(CARRY[3]), .SUM(SUM[3]));
	FA FA_only (.A(A[2]), .B(B[0]), .CIN(EXTRA_2),   .COUT(CARRY[4]), .SUM(SUM[4]));
    HA HA_3 (.A(A[3]), .B(B[1]),    .COUT(CARRY[5]), .SUM(SUM[5]));
    HA HA_4 (.A(A[4]), .B(B[2]),    .COUT(CARRY[6]), .SUM(SUM[6]));
    HA HA_5 (.A(A[5]), .B(B[3]),    .COUT(CARRY[7]), .SUM(SUM[7]));
    HA HA_6 (.A(A[6]), .B(B[4]),    .COUT(CARRY[8]), .SUM(SUM[8]));
    HA HA_7 (.A(A[7]), .B(B[5]),    .COUT(CARRY[9]), .SUM(SUM[9]));
    HA HA_8 (.A(A[8]), .B(B[6]),    .COUT(CARRY[10]),.SUM(SUM[10]));
    HA HA_9 (.A(A[9]), .B(B[7]),    .COUT(_),.SUM(SUM[11]));

endmodule

module CSA_1 (A, B, C, CARRY, SUM);
    input [11:0] A;
	input [11:0] B;
	input [10:0] C;
    output [11:0] CARRY;
	output [12:0] SUM;
	
    // HA HA_1 (.A(A[0]), .B(B[0]), .COUT(CARRY[0]), .SUM(SUM[0]));
	// FA FA_1 (.A(A[1]), .B(B[1]), .CIN(C[0]), .COUT(CARRY[1]), .SUM(SUM[1]));
	// FA FA_2 (.A(A[2]), .B(B[2]), .CIN(C[1]), .COUT(CARRY[2]), .SUM(SUM[2]));
	// FA FA_3 (.A(A[3]), .B(B[3]), .CIN(C[2]), .COUT(CARRY[3]), .SUM(SUM[3]));
	// FA FA_4 (.A(A[4]), .B(B[4]), .CIN(C[3]), .COUT(CARRY[4]), .SUM(SUM[4]));
	// FA FA_5 (.A(A[5]), .B(B[5]), .CIN(C[4]), .COUT(CARRY[5]), .SUM(SUM[5]));
	// FA FA_6 (.A(A[6]), .B(B[6]), .CIN(C[5]), .COUT(CARRY[6]), .SUM(SUM[6]));
	// FA FA_7 (.A(A[7]), .B(B[7]), .CIN(C[6]), .COUT(CARRY[7]), .SUM(SUM[7]));
	// FA FA_8 (.A(A[8]), .B(B[8]), .CIN(C[7]), .COUT(CARRY[8]), .SUM(SUM[8]));
	// FA FA_9 (.A(A[9]), .B(B[9]), .CIN(C[8]), .COUT(CARRY[9]), .SUM(SUM[9]));
	// HA HA_2 (.A(B[10]), .B(C[9]), .COUT(CARRY[10]), .SUM(SUM[10]));
	// HA HA_3 (.A(B[11]), .B(C[10]), .COUT(L1), .SUM(SUM[11]));
	
	// assign CARRY[11] = CARRY[10];
	// assign SUM[12] = SUM[11];
	
    HA HA_1 (.A(A[0]), .B(B[0]), .COUT(CARRY[0]), .SUM(SUM[0]));
	FA FA_1 (.A(A[1]), .B(B[1]), .CIN(C[0]), .COUT(CARRY[1]), .SUM(SUM[1]));
	FA FA_2 (.A(A[2]), .B(B[2]), .CIN(C[1]), .COUT(CARRY[2]), .SUM(SUM[2]));
	FA FA_3 (.A(A[3]), .B(B[3]), .CIN(C[2]), .COUT(CARRY[3]), .SUM(SUM[3]));
	FA FA_4 (.A(A[4]), .B(B[4]), .CIN(C[3]), .COUT(CARRY[4]), .SUM(SUM[4]));
	FA FA_5 (.A(A[5]), .B(B[5]), .CIN(C[4]), .COUT(CARRY[5]), .SUM(SUM[5]));
	FA FA_6 (.A(A[6]), .B(B[6]), .CIN(C[5]), .COUT(CARRY[6]), .SUM(SUM[6]));
	FA FA_7 (.A(A[7]), .B(B[7]), .CIN(C[6]), .COUT(CARRY[7]), .SUM(SUM[7]));
	FA FA_8 (.A(A[8]), .B(B[8]), .CIN(C[7]), .COUT(CARRY[8]), .SUM(SUM[8]));
	FA FA_9 (.A(A[9]), .B(B[9]), .CIN(C[8]), .COUT(CARRY[9]), .SUM(SUM[9]));
	FA FA_10(.A(A[10]), .B(B[10]), .CIN(C[9]), .COUT(CARRY[10]), .SUM(SUM[10]));
	FA FA_11(.A(A[11]), .B(B[11]), .CIN(C[10]), .COUT(CARRY[11]), .SUM(SUM[11]));
	
	assign SUM[12] = SUM[11];

endmodule

module CSA_2 (A, B, C, CARRY, SUM);
    input [12:0] A;
	input [11:0] B;
	input [12:0] C;
    output [12:0] CARRY;
	output [12:0] SUM;
	
	assign CARRY[0] = 1'b0;
    HA HA_1  (.A(A[0]),  .B(C[0]), .COUT(CARRY[1]), .SUM(SUM[0]));
	FA FA_1  (.A(A[1]),  .B(B[0]), .CIN(C[1]),  .COUT(CARRY[2]),  .SUM(SUM[1]));
	FA FA_2  (.A(A[2]),  .B(B[1]), .CIN(C[2]),  .COUT(CARRY[3]),  .SUM(SUM[2]));
	FA FA_3  (.A(A[3]),  .B(B[2]), .CIN(C[3]),  .COUT(CARRY[4]),  .SUM(SUM[3]));
	FA FA_4  (.A(A[4]),  .B(B[3]), .CIN(C[4]),  .COUT(CARRY[5]),  .SUM(SUM[4]));
	FA FA_5  (.A(A[5]),  .B(B[4]), .CIN(C[5]),  .COUT(CARRY[6]),  .SUM(SUM[5]));
	FA FA_6  (.A(A[6]),  .B(B[5]), .CIN(C[6]),  .COUT(CARRY[7]),  .SUM(SUM[6]));
	FA FA_7  (.A(A[7]),  .B(B[6]), .CIN(C[7]),  .COUT(CARRY[8]),  .SUM(SUM[7]));
	FA FA_8  (.A(A[8]),  .B(B[7]), .CIN(C[8]),  .COUT(CARRY[9]),  .SUM(SUM[8]));
	FA FA_9  (.A(A[9]),  .B(B[8]), .CIN(C[9]),  .COUT(CARRY[10]), .SUM(SUM[9]));
	FA FA_10 (.A(A[10]), .B(B[9]), .CIN(C[10]), .COUT(CARRY[11]), .SUM(SUM[10]));
	FA FA_11 (.A(A[11]), .B(B[10]),.CIN(C[11]), .COUT(CARRY[12]), .SUM(SUM[11]));
	FA FA_12 (.A(A[12]), .B(B[11]),.CIN(C[12]), .COUT(_), .SUM(SUM[12]));

endmodule

module CSA_3 (S0, A, B, CARRY, SUM);
    input [12:0] A;
	input [12:0] B;
	input S0;
    output [12:0] CARRY;
	output [12:0] SUM;
	
	assign CARRY[0] = 1'b0;
	FA FA_1  (.A(A[0]),  .B(B[0]),  .CIN(S0),  .COUT(CARRY[1]),  .SUM(SUM[0]));
	HA HA_1  (.A(A[1]),  .B(B[1]),  .COUT(CARRY[2]),  .SUM(SUM[1]));
	HA HA_2  (.A(A[2]),  .B(B[2]),  .COUT(CARRY[3]),  .SUM(SUM[2]));
	HA HA_3  (.A(A[3]),  .B(B[3]),  .COUT(CARRY[4]),  .SUM(SUM[3]));
	HA HA_4  (.A(A[4]),  .B(B[4]),  .COUT(CARRY[5]),  .SUM(SUM[4]));
	HA HA_5  (.A(A[5]),  .B(B[5]),  .COUT(CARRY[6]),  .SUM(SUM[5]));
	HA HA_6  (.A(A[6]),  .B(B[6]),  .COUT(CARRY[7]),  .SUM(SUM[6]));
	HA HA_7  (.A(A[7]),  .B(B[7]),  .COUT(CARRY[8]),  .SUM(SUM[7]));
	HA HA_8  (.A(A[8]),  .B(B[8]),  .COUT(CARRY[9]),  .SUM(SUM[8]));
	HA HA_9  (.A(A[9]),  .B(B[9]),  .COUT(CARRY[10]),  .SUM(SUM[9]));
	HA HA_10 (.A(A[10]), .B(B[10]), .COUT(CARRY[11]), .SUM(SUM[10]));
	HA HA_11 (.A(A[11]), .B(B[11]), .COUT(CARRY[12]), .SUM(SUM[11]));
	HA HA_12 (.A(A[12]), .B(B[12]), .COUT(_), .SUM(SUM[12]));

endmodule

///////////////////////////////////////////////
//         Carry Look-Ahead Adder            //
///////////////////////////////////////////////
module FA_CLA (INA, INB, CIN, RESULT);
	input [12:0] INA;
	input [12:0] INB;
	input CIN;
	output [12:0] RESULT;
	
	wire [2:0] C, C_0, C_1, C_2, C_3;
	
	P_G_ckt   X_PG_0    (.INA(INA[0]),  .INB(INB[0]),  .PPG(_small_P0),  .GNRT(_small_G0));
	P_G_ckt   X_PG_1    (.INA(INA[1]),  .INB(INB[1]),  .PPG(_small_P1),  .GNRT(_small_G1));
	P_G_ckt   X_PG_2    (.INA(INA[2]),  .INB(INB[2]),  .PPG(_small_P2),  .GNRT(_small_G2));
	P_G_ckt   X_PG_3    (.INA(INA[3]),  .INB(INB[3]),  .PPG(_small_P3),  .GNRT(_small_G3));
	P_G_ckt   X_PG_4    (.INA(INA[4]),  .INB(INB[4]),  .PPG(_small_P4),  .GNRT(_small_G4));
	P_G_ckt   X_PG_5    (.INA(INA[5]),  .INB(INB[5]),  .PPG(_small_P5),  .GNRT(_small_G5));
	P_G_ckt   X_PG_6    (.INA(INA[6]),  .INB(INB[6]),  .PPG(_small_P6),  .GNRT(_small_G6));
	P_G_ckt   X_PG_7    (.INA(INA[7]),  .INB(INB[7]),  .PPG(_small_P7),  .GNRT(_small_G7));
	P_G_ckt   X_PG_8    (.INA(INA[8]),  .INB(INB[8]),  .PPG(_small_P8),  .GNRT(_small_G8));
	P_G_ckt   X_PG_9    (.INA(INA[9]),  .INB(INB[9]),  .PPG(_small_P9),  .GNRT(_small_G9));
	P_G_ckt   X_PG_10   (.INA(INA[10]), .INB(INB[10]), .PPG(_small_P10), .GNRT(_small_G10));
	P_G_ckt   X_PG_11   (.INA(INA[11]), .INB(INB[11]), .PPG(_small_P11), .GNRT(_small_G11));
	
	CLL_3bit  X_CLL_top (.IN_P({_big_P2,    _big_P1,    _big_P0}),   .IN_G({_big_G2,    _big_G1,    _big_G0}),   .CIN(CIN), .COUT(C),   .P(P_top),   .G(G_top));
	CLL_3bit  X_CLL_0   (.IN_P({_small_P2,  _small_P1,  _small_P0}), .IN_G({_small_G2,  _small_G1,  _small_G0}), .CIN(CIN), .COUT(C_0), .P(_big_P0), .G(_big_G0));
	CLL_3bit  X_CLL_1   (.IN_P({_small_P5,  _small_P4,  _small_P3}), .IN_G({_small_G5,  _small_G4,  _small_G3}), .CIN(C[0]),.COUT(C_1), .P(_big_P1), .G(_big_G1));
	CLL_3bit  X_CLL_2   (.IN_P({_small_P8,  _small_P7,  _small_P6}), .IN_G({_small_G8,  _small_G7,  _small_G6}), .CIN(C[1]),.COUT(C_2), .P(_big_P2), .G(_big_G2));
	CLL_3bit  X_CLL_3   (.IN_P({_small_P11, _small_P10, _small_P9}), .IN_G({_small_G11, _small_G10, _small_G9}), .CIN(C[2]),.COUT(C_3), .P(_big_P3), .G(_big_G3));
	
	FA_sum    X_FA_sum0 (.A(INA[0]),  .B(INB[0]),  .CIN(CIN),    .SUM(RESULT[0]));
	FA_sum    X_FA_sum1 (.A(INA[1]),  .B(INB[1]),  .CIN(C_0[0]), .SUM(RESULT[1]));
	FA_sum    X_FA_sum2 (.A(INA[2]),  .B(INB[2]),  .CIN(C_0[1]), .SUM(RESULT[2]));
	FA_sum    X_FA_sum3 (.A(INA[3]),  .B(INB[3]),  .CIN(C_0[2]), .SUM(RESULT[3]));
	FA_sum    X_FA_sum4 (.A(INA[4]),  .B(INB[4]),  .CIN(C_1[0]), .SUM(RESULT[4]));
	FA_sum    X_FA_sum5 (.A(INA[5]),  .B(INB[5]),  .CIN(C_1[1]), .SUM(RESULT[5]));
	FA_sum    X_FA_sum6 (.A(INA[6]),  .B(INB[6]),  .CIN(C_1[2]), .SUM(RESULT[6]));
	FA_sum    X_FA_sum7 (.A(INA[7]),  .B(INB[7]),  .CIN(C_2[0]), .SUM(RESULT[7]));
	FA_sum    X_FA_sum8 (.A(INA[8]),  .B(INB[8]),  .CIN(C_2[1]), .SUM(RESULT[8]));
	FA_sum    X_FA_sum9 (.A(INA[9]),  .B(INB[9]),  .CIN(C_2[2]), .SUM(RESULT[9]));
	FA_sum    X_FA_sum10(.A(INA[10]), .B(INB[10]), .CIN(C_3[0]), .SUM(RESULT[10]));
	FA_sum    X_FA_sum11(.A(INA[11]), .B(INB[11]), .CIN(C_3[1]), .SUM(RESULT[11]));
	FA_sum    X_FA_sum12(.A(INA[12]), .B(INB[12]), .CIN(C_3[2]), .SUM(RESULT[12]));
	
endmodule

module CLL_3bit (IN_P, IN_G, CIN, COUT, P, G);	// Carry Look-Ahead Logic for 3bit
    input [2:0] IN_P;
	input [2:0] IN_G;
	input CIN;
    output [2:0] COUT;
	output P, G;
	
	VLSI_NOT   X_NOT_1    (.IN(CIN),                     .OUT(_CIN));
	VLSI_OR2   X_OR_1     (.INA(IN_P[0]), .INB(_CIN),    .OUT(N1));
	VLSI_NAND2 X_NAND_1   (.INA(IN_G[0]), .INB(N1),      .OUT(COUT[0]));
	
	VLSI_NOR2  X_NOR_2    (.INA(IN_P[1]), .INB(IN_P[0]), .OUT(N2));
	VLSI_OR2   X_OR_2     (.INA(IN_G[0]), .INB(IN_P[1]), .OUT(N3));
	VLSI_AND2  X_AND_2    (.INA(IN_G[1]), .INB(N3),      .OUT(N5));
	VLSI_NAND2 X_NAND_2_1 (.INA(N2),      .INB(CIN),     .OUT(N4));
	VLSI_NAND2 X_NAND_2_2 (.INA(N5),      .INB(N4),      .OUT(COUT[1]));
	
	VLSI_NOR2  X_NOR_3    (.INA(IN_P[2]), .INB(IN_P[1]), .OUT(N6));
	VLSI_OR2   X_OR_3     (.INA(IN_G[1]), .INB(IN_P[2]), .OUT(N7));
	VLSI_AND2  X_AND_3    (.INA(IN_G[2]), .INB(N7),      .OUT(N9));
	VLSI_NAND2 X_NAND_3_1 (.INA(N6),      .INB(COUT[0]), .OUT(N8));
	VLSI_NAND2 X_NAND_3_2 (.INA(N9),      .INB(N8),      .OUT(COUT[2]));
	
	VLSI_OR2   X_OR       (.INA(IN_P[2]), .INB(N3),      .OUT(N10));
	VLSI_AND2  X_AND      (.INA(N10),     .INB(N9),      .OUT(G));
	VLSI_NOT   X_NOT      (.IN(IN_P[2]),                 .OUT(_IN_P_2));
	VLSI_NAND2 X_NAND     (.INA(_IN_P_2), .INB(N2),      .OUT(P));

endmodule

module P_G_ckt (INA, INB, PPG, GNRT);
	input INA, INB;
	output PPG, GNRT;
	
	VLSI_NAND2 X_NAND1 (.INA(INA), .INB(INB), .OUT(GNRT));
	VLSI_NOR2  X_NOR1  (.INA(INA), .INB(INB), .OUT(PPG));
	
endmodule

///////////////////////////////////////////////
//                Full Adder                 //
///////////////////////////////////////////////
module FA (A, B, CIN, COUT, SUM);
    input A, B, CIN;
    output COUT, SUM;

    // You can compare the performance difference of following two design

    // Design 1:
    VLSI_XOR3  X_XOR3_1  (.OUT(SUM),  .INA(A),  .INB(B), .INC(CIN));
    VLSI_NAND2 X_NAND2_1 (.OUT(L1),   .INA(A),  .INB(B));
    VLSI_NAND2 X_NAND2_2 (.OUT(L2),   .INA(B),  .INB(CIN));
    VLSI_NAND2 X_NAND2_3 (.OUT(L3),   .INA(A),  .INB(CIN));
    VLSI_NAND3 X_NAND3_1 (.OUT(COUT), .INA(L1), .INB(L2), .INC(L3));

    // Design 2:
    // HA HA0 (.A(A), .B(B), .COUT(c0), .SUM(s0));
    // HA HA1 (.A(s0), .B(CIN), .COUT(c1), .SUM(SUM));
    // VLSI_OR2 OR0 (.INA(c0), .INB(c1), .OUT(COUT));

endmodule

module FA_sum (A, B, CIN, SUM);
    input A, B, CIN;
    output SUM;

    VLSI_XOR3  X_XOR3_1  (.OUT(SUM),  .INA(A),  .INB(B), .INC(CIN));
	
endmodule


///////////////////////////////////////////////
//                Half Adder                 //
///////////////////////////////////////////////
module HA (A, B, COUT, SUM);
    input A, B;
    output COUT, SUM;

    VLSI_XOR2 X_XOR2_0 (.OUT(SUM), .INA(A), .INB(B));
    VLSI_AND2 X_AND2_0 (.OUT(COUT), .INA(A), .INB(B));

endmodule


///////////////////////////////////////////////
//            2-to-1 Multiplexer             //
///////////////////////////////////////////////
module MUX_2X1 (SEL, DATA0, DATA1, OUT);	// A*B +- ACC -> DATA0,   A +- B -> DATA1
	input SEL;
	input  [12:0] DATA0;
	input  [12:0] DATA1;
	output [12:0] OUT;
	
	VLSI_NOT   X_NOT  (.IN(SEL), .OUT(_SEL));
	
	VLSI_NAND2 X_NAND1_1  (.INA(DATA0[0]),  .INB(_SEL), .OUT(L1_1));
	VLSI_NAND2 X_NAND1_2  (.INA(DATA1[0]),  .INB(SEL),  .OUT(L1_2));
	VLSI_NAND2 X_NAND1_3  (.INA(L1_1),      .INB(L1_2),.OUT(OUT[0]));
	
	VLSI_NAND2 X_NAND2_1  (.INA(DATA0[1]),  .INB(_SEL), .OUT(L2_1));
	VLSI_NAND2 X_NAND2_2  (.INA(DATA1[1]),  .INB(SEL),  .OUT(L2_2));
	VLSI_NAND2 X_NAND2_3  (.INA(L2_1),      .INB(L2_2),.OUT(OUT[1]));
	
	VLSI_NAND2 X_NAND3_1  (.INA(DATA0[2]),  .INB(_SEL), .OUT(L3_1));
	VLSI_NAND2 X_NAND3_2  (.INA(DATA1[2]),  .INB(SEL),  .OUT(L3_2));
	VLSI_NAND2 X_NAND3_3  (.INA(L3_1),      .INB(L3_2),.OUT(OUT[2]));
	
	VLSI_NAND2 X_NAND4_1  (.INA(DATA0[3]),  .INB(_SEL), .OUT(L4_1));
	VLSI_NAND2 X_NAND4_2  (.INA(DATA1[3]),  .INB(SEL),  .OUT(L4_2));
	VLSI_NAND2 X_NAND4_3  (.INA(L4_1),      .INB(L4_2),.OUT(OUT[3]));
	
	VLSI_NAND2 X_NAND5_1  (.INA(DATA0[4]),  .INB(_SEL), .OUT(L5_1));
	VLSI_NAND2 X_NAND5_2  (.INA(DATA1[4]),  .INB(SEL),  .OUT(L5_2));
	VLSI_NAND2 X_NAND5_3  (.INA(L5_1),      .INB(L5_2),.OUT(OUT[4]));
	
	VLSI_NAND2 X_NAND6_1  (.INA(DATA0[5]),  .INB(_SEL), .OUT(L6_1));
	VLSI_NAND2 X_NAND6_2  (.INA(DATA1[5]),  .INB(SEL),  .OUT(L6_2));
	VLSI_NAND2 X_NAND6_3  (.INA(L6_1),      .INB(L6_2),.OUT(OUT[5]));
	
	VLSI_NAND2 X_NAND7_1  (.INA(DATA0[6]),  .INB(_SEL), .OUT(L7_1));
	VLSI_NAND2 X_NAND7_2  (.INA(DATA1[6]),  .INB(SEL),  .OUT(L7_2));
	VLSI_NAND2 X_NAND7_3  (.INA(L7_1),      .INB(L7_2),.OUT(OUT[6]));
	
	VLSI_NAND2 X_NAND8_1  (.INA(DATA0[7]),  .INB(_SEL), .OUT(L8_1));
	VLSI_NAND2 X_NAND8_2  (.INA(DATA1[7]),  .INB(SEL),  .OUT(L8_2));
	VLSI_NAND2 X_NAND8_3  (.INA(L8_1),      .INB(L8_2),.OUT(OUT[7]));
	
	VLSI_NAND2 X_NAND9_1  (.INA(DATA0[8]),  .INB(_SEL), .OUT(L9_1));
	VLSI_NAND2 X_NAND9_2  (.INA(DATA1[8]),  .INB(SEL),  .OUT(L9_2));
	VLSI_NAND2 X_NAND9_3  (.INA(L9_1),      .INB(L9_2),.OUT(OUT[8]));
	
	VLSI_NAND2 X_NAND10_1  (.INA(DATA0[9]),  .INB(_SEL),  .OUT(L10_1));
	VLSI_NAND2 X_NAND10_2  (.INA(DATA1[9]),  .INB(SEL),   .OUT(L10_2));
	VLSI_NAND2 X_NAND10_3  (.INA(L10_1),     .INB(L10_2),.OUT(OUT[9]));
	
	VLSI_NAND2 X_NAND11_1  (.INA(DATA0[10]), .INB(_SEL),  .OUT(L11_1));
	VLSI_NAND2 X_NAND11_2  (.INA(DATA1[10]), .INB(SEL),   .OUT(L11_2));
	VLSI_NAND2 X_NAND11_3  (.INA(L11_1),     .INB(L11_2),.OUT(OUT[10]));
	
	VLSI_NAND2 X_NAND12_1  (.INA(DATA0[11]), .INB(_SEL),  .OUT(L12_1));
	VLSI_NAND2 X_NAND12_2  (.INA(DATA1[11]), .INB(SEL),   .OUT(L12_2));
	VLSI_NAND2 X_NAND12_3  (.INA(L12_1),     .INB(L12_2),.OUT(OUT[11]));
	
	VLSI_NAND2 X_NAND13_1  (.INA(DATA0[12]), .INB(_SEL),  .OUT(L13_1));
	VLSI_NAND2 X_NAND13_2  (.INA(DATA1[12]), .INB(SEL),   .OUT(L13_2));
	VLSI_NAND2 X_NAND13_3  (.INA(L13_1),     .INB(L13_2),.OUT(OUT[12]));
	
endmodule


///////////////////////////////////////////////
//            Reverse using XOR              //
///////////////////////////////////////////////
module REV_13bit (SEL, IN, OUT);
	input SEL;
	input [12:0] IN;
	output [12:0] OUT;
	
	VLSI_XOR2  X_XOR_0 (.INA(SEL), .INB(IN[0]), .OUT(OUT[0]));
	VLSI_XOR2  X_XOR_1 (.INA(SEL), .INB(IN[1]), .OUT(OUT[1]));
	VLSI_XOR2  X_XOR_2 (.INA(SEL), .INB(IN[2]), .OUT(OUT[2]));
	VLSI_XOR2  X_XOR_3 (.INA(SEL), .INB(IN[3]), .OUT(OUT[3]));
	VLSI_XOR2  X_XOR_4 (.INA(SEL), .INB(IN[4]), .OUT(OUT[4]));
	VLSI_XOR2  X_XOR_5 (.INA(SEL), .INB(IN[5]), .OUT(OUT[5]));
	VLSI_XOR2  X_XOR_6 (.INA(SEL), .INB(IN[6]), .OUT(OUT[6]));
	VLSI_XOR2  X_XOR_7 (.INA(SEL), .INB(IN[7]), .OUT(OUT[7]));
	VLSI_XOR2  X_XOR_8 (.INA(SEL), .INB(IN[8]), .OUT(OUT[8]));
	VLSI_XOR2  X_XOR_9 (.INA(SEL), .INB(IN[9]), .OUT(OUT[9]));
	VLSI_XOR2  X_XOR_10(.INA(SEL), .INB(IN[10]), .OUT(OUT[10]));
	VLSI_XOR2  X_XOR_11(.INA(SEL), .INB(IN[11]), .OUT(OUT[11]));
	VLSI_XOR2  X_XOR_12(.INA(SEL), .INB(IN[12]), .OUT(OUT[12]));
endmodule