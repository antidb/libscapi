#ifndef CIRCUIT_H_
#define CIRCUIT_H_

#include "TGate.hpp"
#include <vector>
#include <string>

/**
* A software representation of the structure of an arithmetic circuit.
* The circuit consists of Input, Addition, Multiplication, and Output gates. Technically, a circuit
* is essentially an array of gates, with some bookkeeping information. Each gate has associated input wires
* (at most 2) and output wire (at most 1). Input and Output gates also have an associated party.
* We assume that the gates in the circuit are ordered, i.e., each gate only depends on gates with smaller
* index.
*
*/

using namespace std;


class ArithmeticCircuit
{
private:

    vector<TGate> gates;
    int nrOfMultiplicationGates = 0;
    int nrOfAdditionGates = 0;
    int nrOfSubtractionGates = 0;
    int nrOfRandomGates = 0;
    int nrOfScalarMultGates = 0;
    int nrOfInputGates = 0;
    int nrOfOutputGates = 0;
    int nrOfSumProductsGates = 0;

    bool isCircuitArranged = false;
    vector<int> layersIndices;

public:

    ArithmeticCircuit();
    ~ArithmeticCircuit();

    /**
    * This method reads text file and creates an object of ArythmeticCircuit according to the file.
    * This includes creating the gates and other information about the parties involved.
    *
    */
    void readCircuit(const char* fileName);

    void writeToFile(string outputFileName,int numberOfParties);

    //get functions
    int getNrOfMultiplicationGates() { return nrOfMultiplicationGates; }
    int getNrOfAdditionGates() { return nrOfAdditionGates; }
    int getNrSubtractionGates() {return nrOfSubtractionGates; }
    int getNrOfRandomGates() {return nrOfRandomGates; }
    int getNrOfScalarMultGates() {return nrOfScalarMultGates;}
    int getNrOfInputGates() { return nrOfInputGates; }
    int getNrOfOutputGates() { return nrOfOutputGates; }
    int getNrOfSumOfProductsGates() { return nrOfSumProductsGates; }
    int getNrOfGates() { return (nrOfMultiplicationGates +
                                 nrOfSubtractionGates +
                                 nrOfRandomGates +
                                 nrOfScalarMultGates +
                                 nrOfAdditionGates +
                                 nrOfSumProductsGates +
                                 nrOfInputGates +
                                 nrOfOutputGates); }


    /**
    * This method rearranges the gates to be ordered by depth.
    * After the new order is calculated, it is copied to the vector of gates and replaces
    * the gates that were read from the file.
    *
    */
    void reArrangeCircuit();

    vector<TGate> const & getGates() const {	return gates;};
    vector<int> const & getLayers() const {	return layersIndices;};

};

#endif /* CIRCUIT_H_ */