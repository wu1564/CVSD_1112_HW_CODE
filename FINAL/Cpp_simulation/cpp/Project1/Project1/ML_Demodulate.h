#pragma once

#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include <limits.h>
#include "Complex.h"

#define REAL 4
#define AD_FRACTION  0 // 0-- > 4.16 if 1-- > 4.15
#define FIXPOINT  (16 - AD_FRACTION)
#define DATA_W  (REAL + FIXPOINT)
#define LLR_DATA_W  8

typedef long long int LLI;

class ML_Demodulate {
	public:
		ML_Demodulate();
		void getY(const std::string& inputY_buff, std::vector<Complex>& inputY);
		void getR(const std::string& inputR_buff, std::vector<std::vector<Complex>>& matrixR);
		// Operation Unit
		LLI extension(LLI input, int extenBit);
		LLI hardwareAdd(LLI input1, LLI input2, int inputBits);
		LLI hardwareSub(LLI input1, LLI input2, int inputBits);
		LLI hardwareMult(LLI input1, LLI input2, int inputBits, int outputBits, int fixedOutput);
		Complex complexSubtract(const Complex& target1, const Complex& target2, int inputBits);
		Complex complexMult(const Complex& target1, const Complex& target2);
		LLI complexNorm2(const Complex& target);

		// ML Algorithm
		LLI minPartialCal(const std::vector<Complex>& inputY, const std::vector<std::vector<Complex>>& matrixR, int index, int bitIndex);
		LLI partialCal(const std::vector<Complex>& inputY, const std::vector<std::vector<Complex>>& matrixR, const std::vector<Complex>& signalS);
		void ML_LLR(const std::vector<Complex>& inputY, const std::vector<std::vector<Complex>>& matrixR, std::vector<int>& o_LLR, std::vector<int>& o_hardBit);

		// validation function
		int validateOutput(std::vector<int>& o_LLR, std::vector<int>& o_hardBit, std::vector<int>& goldenHardbit, int goldenIndex);
		void validateErrorRate(int ErrorRate, int SNR);

		// Debug Function
		void checkInpuutY(std::vector<Complex> inputY);
		void checkInpuutR(std::vector<std::vector<Complex>> matirxR);
	private:
		Complex S_OP1;
		Complex S_OP2;
		Complex S_OP3;
		Complex S_OP4;
};
