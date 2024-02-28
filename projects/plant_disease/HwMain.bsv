import Clocks::*;
import Vector::*;
import Matrix::*;


interface HwMainIfc;
	method ActionValue#(Bit#(8)) serial_tx;
	method Action serial_rx(Bit#(8) rx);
endinterface

module mkHwMain#(Ulx3sSdramuserIfc mem) (HwMainIfc);

	Clock clk <- exposeCurrentClock;
	Reset rst <- exposeCurrentReset;

	MatMulIfc#(64) matmul_unit <- mkMatMul64;
endmodule
