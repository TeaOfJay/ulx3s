
// typedef enum { ACCUM, } State deriving(Bits, Eq);
import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAMFIFO::*;

import SimpleFloat::*;
import FloatingPoint::*;

interface VarPIfc;


	method Action putMusq(Float m);  //put mean squared
	method Action putInput(Float i);

endinterface



method mkVarP#(numeric type log_dim, numeric type dim);
	//input queues
	FIFO#(Float) musqQ <- mkFIFO;
	FIFO#(Float)   inQ <- mkFIFO;
	FIFO#(Float)  outQ <- mkFIFO;

	FloatTwoOp fsquare <- mkFloatMult;
	FloatTwoOp faccum  <- mkFloatAdd;

	FloatTwoOp fadd    <- mkFloatAdd;

	BypassWire#(Float) accum <- mkBypassWire(0);

	//control
	Reg#(Bit#(log_dim)) count <- mkReg(0);

	function Float negate(Float float32);
        Bit#(32) bits = pack(float32); 
        bits[31] = ~bits[31];
        return unpack(bits);
    endfunction

	rule relayMean;
		muQ.deq;
		mean <= muQ.first;
	endrule

	rule calcSquare;
		inQ.deq;
		fsquare.put(inQ.first, inQ.first);
	endrule 

	rule calcAccum;
		let square <- fsquare.get;
		faccum.put(square, accum);
	endrule 

	rule relayAccum(count < dim);
		let new_accum <- faccum.get;
		accum = new_accum;

		count <= count + 1;
	endrule

	rule calcSub(count == dim);
		musqQ.deq;
		

		fadd.put(negate(accum) >> log_dim, musqQ.first); // mu^2 - E[X^2]
		count <= 0;
	endrule 

	rule relayVar;
		let variance <- fadd.get;

		outQ.enq(variance);
	endrule

	// 	if(inflight) begin 
	// 		let sum_result <- faccum.get;
	// 		accum <= sum_result;

	// 	let square <- fsquare.get;
	// 	faccum.put(square, curr_accum);
	// endrule



	method Action putMusq(Float musq);
		musqQ.enq(musq);
	endmethod  

	method ActionValue#(Float) get;
		outQ.deq;
		return outQ.first;
	endmethod
endmodule 

// 	interface LayerNormIfc#(numeric type elements);
// 	method Action put(Float w);
// 	//should we precompute mean and variance?

// 	method Float get;
// 	method Bool resultReady;
// endinterface