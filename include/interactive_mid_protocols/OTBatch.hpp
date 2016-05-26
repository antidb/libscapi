#pragma once
#include "../infra/Common.hpp"

/**
* This interface is a marker interface for OT sender output, where there is an implementing class for each OT protocol that has an output.<p>
* Most OT senders output nothing. However in the batch scenario there may be cases where the protocol wishes to output x0 and x1 instead of inputting it.
* Every concrete protocol outputs different data. But all must return an implemented class of this interface or null.
*/
class OTBatchSOutput {};

enum class OTBatchSInputTypes { OTExtensionGeneralSInput };

/**
* Every Batch OT sender needs inputs during the protocol execution, but every concrete protocol needs
* different inputs.<p>
* This interface is a marker interface for OT Batch sender input, where there is an implementing class
* for each OT protocol.
*/
class OTBatchSInput {
public:
	virtual OTBatchSInputTypes getType() = 0;
};

/**
* A concrete class for OT extension input for the sender. <p>
* In the general OT extension scenario the sender gets x0 and x1 for each OT.
*/
class OTExtensionGeneralSInput : public OTBatchSInput {
private:
	vector<byte> x0Arr;	// An array that holds all the x0 for all the senders serially. 
					// For optimization reasons, all the x0 inputs are held in one dimensional array one after the other 
					// rather than a two dimensional array. 
					// The size of each element can be calculated by x0ArrSize/numOfOts.
	vector<byte> x1Arr;	// An array that holds all the x1 for all the senders serially. 
	int numOfOts;	// Number of OTs in the OT extension.

public:
	OTBatchSInputTypes getType() override { return OTBatchSInputTypes::OTExtensionGeneralSInput; };
	/**
	* Constructor that sets x0, x1 for each OT element and the number of OTs.
	* @param x1Arr holds all the x0 for all the senders serially.
	* @param x0Arr holds all the x1 for all the senders serially.
	* @param numOfOts Number of OTs in the OT extension.
	*/
	OTExtensionGeneralSInput(vector<byte> x0Arr, vector<byte> x1Arr, int numOfOts) {
		this->x0Arr = x0Arr;
		this->x1Arr = x1Arr;
		this->numOfOts = numOfOts;
	};
	/**
	* @return the array that holds all the x0 for all the senders serially.
	*/
	vector<byte> getX0Arr() { return x0Arr; };
	/**
	* @return the array that holds all the x1 for all the senders serially.
	*/
	vector<byte> getX1Arr() { return x1Arr; };
	/**
	* @return the number of OT elements.
	*/
	int getNumOfOts() { return numOfOts; };
	int getX0ArrSize() { return x0Arr.size(); };
	int getX1ArrSize() { return x1Arr.size(); };
};

/**
* General interface for Batch OT Sender.
* Every class that implements it is signed as Batch Oblivious Transfer sender.
*/
class OTBatchSender {

public:
	/**
	* The transfer stage of OT Batch protocol which can be called several times in parallel.<p>
	* The OT implementation support usage of many calls to transfer, with single preprocess execution. <p>
	* This way, one can execute batch OT by creating the OT receiver once and call the transfer function for each input couple.<p>
	* In order to enable the parallel calls, each transfer call should use a different channel to send and receive messages.<p>
	* This way the parallel executions of the function will not block each other.<p>
	*/
	virtual shared_ptr<OTBatchSOutput> transfer(OTBatchSInput * input) = 0;
};

/**
* Every Batch OT receiver outputs a result in the end of the protocol execution, but every concrete
* protocol output different data.<p>
* This interface is a marker interface for OT receiver output, where there is an implementing class
* for each OT protocol.
*/
class OTBatchROutput {};

/**
* Every OT receiver outputs a result in the end of the protocol execution, but every concrete
* protocol output different data.<p>
* This interface is a marker interface for OT receiver output, where there is an implementing class
* for each OT protocol.
*/
class OTROutput {};

/**
* Concrete implementation of OT receiver (on byteArray) output.<p>
* In the byteArray scenario, the receiver outputs xSigma as a byte array.
* This output class also can be viewed as the output of batch OT when xSigma is a concatenation of all xSigma byte array of all OTs.
*/
class OTOnByteArrayROutput : public OTROutput, public OTBatchROutput {
public:
	OTOnByteArrayROutput(vector<byte> xSigma) { this->xSigma = xSigma; };
	vector<byte> getXSigma() { return xSigma; };
	int getLength() { return xSigma.size(); };
private:
	vector<byte> xSigma;
};

enum class OTBatchRInputTypes { OTExtensionGeneralRInput };

/**
* Every Batch OT receiver needs inputs during the protocol execution, but every concrete protocol needs
* different inputs.<p>
* This interface is a marker interface for OT receiver input, where there is an implementing class
* for each OT protocol.
*/
class OTBatchRInput {
public:
	virtual OTBatchRInputTypes getType() = 0;
};

/**
* An abstract OT receiver input.<P>
* All the concrete classes are the same and differ only in the name.
* The reason a class is created for each version is due to the fact that a respective class is created for the sender and we wish to be consistent.
* The name of the class determines the version of the OT extension we wish to run.
* In all OT extension scenarios the receiver gets i bits. Each byte holds a bit for each OT in the OT extension protocol.
*/
class OTExtensionRInput : public OTBatchRInput {
public:
	/**
	* Constructor that sets the sigma array and the number of OT elements.
	* @param sigmaArr An array of sigma for each OT.
	* @param elementSize The size of each element in the OT extension, in bits.
	*/
	OTExtensionRInput(vector<byte> sigmaArr, int elementSize) {
		this->sigmaArr = sigmaArr;
		this->elementSize = elementSize;
	};
	vector<byte> getSigmaArr() { return sigmaArr; };
	int getSigmaArrSize() { return sigmaArr.size(); };
	int getElementSize() { return elementSize; };
	OTBatchRInputTypes getType() { return OTBatchRInputTypes::OTExtensionGeneralRInput; };

private:
	vector<byte> sigmaArr; 		// Each byte holds a sigma bit for each OT in the OT extension protocol.
	int elementSize;	// The size of each element in the ot extension. All elements must be of the same size.
};

/**
* A concrete class for OT extension input for the receiver. <p>
* All the classes are the same and differ only in the name.
* The reason a class is created for each version is due to the fact that a respective class is created for the sender and we wish to be consistent.
* The name of the class determines the version of the OT extension we wish to run and in this case the general case.
*/
class OTExtensionGeneralRInput : public OTExtensionRInput {
public:
	/**
	* Constructor that sets the sigma array and the number of OT elements.
	* @param sigmaArr An array of sigma for each OT.
	* @param elementSize The size of each element in the OT extension, in bits.
	*/
	OTExtensionGeneralRInput(vector<byte> sigmaArr, int elementSize) : OTExtensionRInput(sigmaArr, elementSize) {};
};

/**
* General interface for Batch OT Receiver. <p>
* Every class that implements it is signed as Batch Oblivious Transfer receiver.<p>
*/
class OTBatchReceiver {
	/**
	* The transfer stage of OT Batch protocol which can be called several times in parallel.<p>
	* The OT implementation support usage of many calls to transfer, with single preprocess execution. <p>
	* This way, one can execute batch OT by creating the OT receiver once and call the transfer function for each input couple.<p>
	* In order to enable the parallel calls, each transfer call should use a different channel to send and receive messages.<p>
	* This way the parallel executions of the function will not block each other.<p>
	* @param channel each call should get a different one.
	* @param input The parameters given in the input must match the DlogGroup member of this class, which given in the constructor.
	* @return OTBatchROutput, the output of the protocol.
	*/
public:
	virtual shared_ptr<OTBatchROutput> transfer(OTBatchRInput * input) = 0;
};