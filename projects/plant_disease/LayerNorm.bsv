import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAMFIFO::*;

import SimpleFloat::*;
import FloatingPoint::*;


interface LayerNormIfc(dim);
	method Action put(Float w);
	//should we precompute mean and variance?

	method Float get;
	method Bool resultReady;
endinterface

module mkMAC(MACIfc);
	FloatTwoOp fmult <- mkFloatMult;
	FloatTwoOp fadd  <- mkFloatAdd;

	FIFO#(Tuple2#(Float, Float)) inQ <- mkFIFO;

	FIFOF#(Float) productQ <- mkFIFOF;

	Reg#(Float) accum <- mkReg(0);

	//control signals
	Reg#(Bit#(1)) clear <- mkReg(0);
	Reg#(Bit#(1)) inflight <- mkReg(0);

	rule enqMult;
		inQ.deq;
		
		Tuple2#(Float, Float) pair = inQ.first;

		fmult.put(tpl_1(pair), tpl_2(pair));
	endrule

	rule relayProduct;
		let product <- fmult.get;

		productQ.enq(product);
	endrule

	rule enqSum(inflight == 1'b0);

		productQ.deq;

		fadd.put(productQ.first, accum);
		inflight <= 1'b1;
	endrule
		

	rule relayAccumulate(inflight == 1'b1);
		let accumulate <- fadd.get;
		accum <= (clear) ? 0 : accumulate;

		if(productQ.notEmpty) begin
			productQ.deq;
			fadd.put(productQ.first, accum);
			inflight <= 1'b1;
		end else begin
			inflight <= 1'b0;
		end
	endrule
	
	method Action clear;
		clear <= 0;
	end

	method Action put(Float a, Float b);
		inQ.enq(tuple2(a, b));
	endmethod

	method Float get = accum;
	method Bool  resultReady = ~inflight;
endmodule



interface MatMulIfc#(numeric type elements);

	method Action  putMatrixLeft(Vector#(elements, Float) matrix);
	method Action putMatrixRight(Vector#(elements, Float) matrix);

	method ActionValue#(Vector#(elements, Float)) get;
	method Bool resultExists;
endinterface

type 6 LOG_PE
typedef TExp#(LOG_PE) N_PE
module mkMatMul(MatMulIfc#(N_PE));

	Vector#(N_PE, MACIfc) processing_elements;

	for(Integer i = 0; i < valueOf(N_PE); i = i+1) begin
		processing_elements <- mkMAC;

		Reg#(Bit#(16))

	end

	method Action putMatrixLeft(Float matrix[elements]);
	method Action putMatrixRight(Float matrix[elements]);
	
	method ActionValue#(Float matrix[elements]) get;
	method Bool resultExists;
	
	
endmodule 



endmodule
