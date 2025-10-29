#include "ML_Demodulate.h"

static LLI maskNumGen() {
	LLI num = 0;
	for (int i = 0; i < DATA_W; ++i) {
		num |= 1 << i;
	}
	return num;
}

static LLI maskNum(int bit) {
	LLI num = 0;
	for (int i = 0; i < bit; ++i) {
		num |= 1 << i;
	}
	return num;
}

ML_Demodulate::ML_Demodulate() {
	this->S_OP1.real = 46341;
	this->S_OP1.imag = 46341;

	this->S_OP2.real = 1002235;
	this->S_OP2.imag = 46341;

	this->S_OP3.real = 1002235;
	this->S_OP3.imag = 1002235;

	this->S_OP4.real = 46341;
	this->S_OP4.imag = 1002235;
}

void ML_Demodulate::getY(const std::string &inputY_buff, std::vector<Complex> &inputY) {
	std::stringstream ss;
	int num;
	Complex complexNum;

	inputY.clear();
	for (int i = 30; i >= 0; i -= 10) {
		ss << std::hex << inputY_buff.substr(i + 5, 5);
		ss >> num;
		complexNum.real = num >> AD_FRACTION;
		ss.clear();
		ss << std::hex << inputY_buff.substr(i, 5);
		ss >> num;
		complexNum.imag = num >> AD_FRACTION;
		ss.clear();
		inputY.push_back(complexNum);
	}	
}

void ML_Demodulate::getR(const std::string &inputR_buff, std::vector<std::vector<Complex>> &matrixR) {
	std::vector<Complex> tempArr;
	Complex complexNum;
	Complex zero;
	std::stringstream ss;
	int num, index = 0;
	for (int i = 3; i >= 0; i--) {
		ss << std::hex << inputR_buff.substr(index, 5);
		ss >> num;
		ss.clear();
		complexNum.real = num >> AD_FRACTION;
		complexNum.imag = 0;
		tempArr.push_back(complexNum);
		index += 5;
		for (int j = 0; j < i; j++) {
			ss << std::hex << inputR_buff.substr(index, 5);
			ss >> num;
			ss.clear();
			complexNum.imag = num >> AD_FRACTION;
			ss << std::hex << inputR_buff.substr(index+5, 5);
			ss >> num;
			ss.clear();
			complexNum.real = num >> AD_FRACTION;
			tempArr.push_back(complexNum);
			index += 10;
		}
	}
	ss << std::hex << inputR_buff.substr(index, 5);
	ss >> num;
	ss.clear();
	complexNum.real = num >> AD_FRACTION;
	complexNum.imag = 0;
	tempArr.push_back(complexNum);
	std::vector<Complex> row1{ tempArr[9], tempArr[8], tempArr[6], tempArr[3] };
	std::vector<Complex> row2{       zero, tempArr[7], tempArr[5], tempArr[2] };
	std::vector<Complex> row3{       zero,       zero, tempArr[4], tempArr[1] };
	std::vector<Complex> row4{       zero,       zero,       zero, tempArr[0] };
	matrixR.clear();
	matrixR.push_back(row1);
	matrixR.push_back(row2);
	matrixR.push_back(row3);
	matrixR.push_back(row4);
}


//-----------------------------------------------------------------------------------------------------
// Computing Functions
//-----------------------------------------------------------------------------------------------------
LLI ML_Demodulate::extension(LLI input, int extenBit) {
	LLI bits = DATA_W - 1;
	LLI mask;

	if (extenBit <= DATA_W) {
		return input;
	}
	mask = maskNum(extenBit-DATA_W);
	if ((input & (1 << bits)) >> bits == 1) {
		return input | (mask << DATA_W);
	}
	return input;
}

LLI ML_Demodulate::hardwareAdd(LLI input1, LLI input2, int inputBits) {
	LLI in1 = extension(input1, inputBits);
	LLI in2 = extension(input2, inputBits);
	return (in1 + in2) & maskNum(inputBits);
}

LLI ML_Demodulate::hardwareSub(LLI input1, LLI input2, int inputBits) {
	LLI in1 = extension(input1, inputBits);
	LLI in2 = extension(input2, inputBits);
	return (in1 + (~in2 + 1)) & maskNum(inputBits);
}

LLI ML_Demodulate::hardwareMult(LLI input1, LLI input2, int inputBits, int outputBits, int fixedOutput) {
	LLI fixOutMask = maskNumGen();
	//print('Multiplier Input', format(int(input1), "#x"), format(int(input2), "#x"))
	LLI mask = maskNum(outputBits - inputBits);
	LLI outputMask = mask | (mask << inputBits);
	LLI temp = extension(input1, outputBits);
	LLI temp2 = extension(input2, outputBits);
	//std::cout << std::hex << "After Signed extension " << temp << " " << temp2 << std::endl;
	LLI mult = temp * temp2;
	LLI signedBit = (mult & (1 << (((LLI)(inputBits * 2)) - 1))) >> (outputBits - 1);
	
	//std::cout << std::hex << mult << " Signedbit: " << signedBit << std::endl;

	if (signedBit){
		mult |= maskNum(FIXPOINT) << (inputBits * 2);
	} else {
		mult &= ~(maskNum(FIXPOINT) << (inputBits * 2));
	}
	//std::cout << std::hex << (LLI)(mult >> FIXPOINT) << std::endl;
	mult = (mult >> FIXPOINT) & outputMask;
	//std::cout << std::hex << mult << std::endl;
	if (fixedOutput) {
		mult &= fixOutMask;
	}
	//std::cout << std::hex << "Actual mult output: " << mult << std::endl;
	// print('')
	return mult;
}


Complex ML_Demodulate::complexSubtract(const Complex& target1, const Complex& target2, int inputBits) {
	int sub1 = hardwareSub(target1.real, target2.real, inputBits);
	int sub2 = hardwareSub(target1.imag, target2.imag, inputBits);;
	return Complex(sub1, sub2);
}

Complex ML_Demodulate::complexMult(const Complex& target1, const Complex& target2) {
	LLI mult1; 
	LLI mult2; 
	LLI goal; 
	LLI goal2;
	mult1 = hardwareMult(target1.real, target2.real, DATA_W, DATA_W + DATA_W, 1);
	mult2 = hardwareMult(target1.imag, target2.imag, DATA_W, DATA_W + DATA_W, 1);
	goal = hardwareSub(mult1, mult2, DATA_W);
	mult1 = hardwareMult(target1.real, target2.imag, DATA_W, DATA_W + DATA_W, 1);
	mult2 = hardwareMult(target1.imag, target2.real, DATA_W, DATA_W + DATA_W, 1);
	goal2 = hardwareAdd(mult1, mult2, DATA_W);
	return Complex(goal, goal2);
}

LLI ML_Demodulate::complexNorm2(const Complex &target) {
	LLI mult1;
	LLI mult2;
	mult1 = hardwareMult(target.real, target.real, DATA_W, DATA_W + DATA_W, 0);
	mult2 = hardwareMult(target.imag, target.imag, DATA_W, DATA_W + DATA_W, 0);
	return mult1 + mult2;
}

LLI ML_Demodulate::partialCal(const std::vector<Complex> &inputY, const std::vector<std::vector<Complex>> &matrixR, const std::vector<Complex> &signalS) {
	int total = 0;
	Complex hatY, temp;

	for (int i = 0; i < 4; ++i) {
		hatY = inputY[i];
		for (int j = i; j < 4; ++j) {
			//std::cout << std::hex << "MatrixR:" << matrixR[i][j].real << " " << matrixR[i][j].imag << std::endl;
			//std::cout << std::hex << "SignalS:" << signalS[j].real << " " << signalS[j].imag << std::endl;
			temp = complexMult(matrixR[i][j], signalS[j]);
			//std::cout << std::hex << "Mult Result:" << temp.real << " " << temp.imag << std::endl;
			hatY = complexSubtract(hatY, temp, DATA_W);
			//std::cout << std::hex << "Sub Result:" << hatY.real << " " << hatY.imag << std::endl;
		}
		total += complexNorm2(hatY);
		//std::cout << std::hex << "Norm Result:" << total << std::endl;
	}
	return total;
}

LLI ML_Demodulate::minPartialCal(const std::vector<Complex> &inputY, const std::vector<std::vector<Complex>> &matrixR, int index, int bitIndex) {
	Complex zero;
	std::vector<Complex> signal_op { S_OP1, S_OP2, S_OP3, S_OP4 };
	std::vector<int> bound{4, 4, 4, 4};
	std::vector<Complex> signalS{ zero, zero, zero, zero};
	LLI minLLR_1, minLLR_0;
	int bit;
	LLI partialLLR;

	minLLR_1 = INT_MAX;
	minLLR_0 = INT_MAX;
	bound[index] = (index < 4) ? 2 : 4;
	for (int i = 0; i < bound[0]; i++) {
		for (int j = 0; j < bound[1]; j++) {
			for (int k = 0; k < bound[2]; k++) {
				for (int h = 0; h < bound[3]; h++) {
					switch (index) {
						case 0:  bit = i; break;
						case 1:  bit = j; break;
						case 2:  bit = k; break;
						case 3:  bit = h; break;
						default: bit = i; break;
					}
					signalS[0] = signal_op[i];
					signalS[1] = signal_op[j];
					signalS[2] = signal_op[k];
					signalS[3] = signal_op[h];

					if (!bitIndex) {
						signalS[index] = (bit) ? signal_op[2] : signal_op[1];
					} else {
						signalS[index] = (bit) ? signal_op[3] : signal_op[2];
					}
					
					partialLLR = partialCal(inputY, matrixR, signalS);
					minLLR_1 = (partialLLR < minLLR_1) ? partialLLR : minLLR_1;
					//std::cout << std::hex << minLLR_1 << std::endl;

					if (!bitIndex) {
						signalS[index] = (bit) ? signal_op[0] : signal_op[3];
					}
					else {
						signalS[index] = (bit) ? signal_op[0] : signal_op[1];
					}
					partialLLR = partialCal(inputY, matrixR, signalS);
					minLLR_0 = (partialLLR < minLLR_0) ? partialLLR : minLLR_0;
					//std::cout << std::hex << minLLR_0 << std::endl;
				}
			}
		}
	}
	return hardwareSub(minLLR_1, minLLR_0, DATA_W + 1);
}

void ML_Demodulate::ML_LLR(const std::vector<Complex>& inputY, const std::vector<std::vector<Complex>>& matrixR, std::vector<int>& o_LLR, std::vector<int>& o_hardBit) {
	LLI resultMask = maskNum(LLR_DATA_W);
	LLI LLR_bit0, LLR_bit1;

	for (int x_index = 0; x_index < 4; x_index++) {
		LLR_bit0 = ((minPartialCal(inputY, matrixR, x_index, 0)) >> (FIXPOINT - 4)) & resultMask;
		o_LLR.push_back(LLR_bit0);
		o_hardBit.push_back((LLR_bit0 >> (LLR_DATA_W - 1)));

		LLR_bit1 = ((minPartialCal(inputY, matrixR, x_index, 1)) >> (FIXPOINT - 4)) & resultMask;
		o_LLR.push_back(LLR_bit1);
		o_hardBit.push_back((LLR_bit1 >> (LLR_DATA_W - 1)));
	}
}

//--------------------------------------------------------------------------------
// Validating Function
//--------------------------------------------------------------------------------
int ML_Demodulate::validateOutput(std::vector<int> &o_LLR, std::vector<int> &o_hardBit, std::vector<int> &goldenHardbit, int goldenIndex) {
	int dataError = 0;
	int Error = 0;

	for (int dataIndex = 0; dataIndex < 8; dataIndex++) {
		if (o_hardBit[dataIndex] != goldenHardbit[goldenIndex + dataIndex] || o_LLR[dataIndex] == 0) {
			dataError++;
			Error = 1;
			break;
		}
	}
	if (Error) {
		std::cout << "Test[" << goldenIndex/8 << "] Wrong !, Your data is:";
		for (auto data : o_hardBit) {
			std::cout << data;
		}
		std::cout << ", and the golden data is:";
		for (int i = 0; i < 8; ++i) {
			std::cout << goldenHardbit[goldenIndex+i];
		}
		std::cout << std::endl;
	}
	return dataError;
}

void ML_Demodulate::validateErrorRate(int ErrorRate, int SNR) {
	float passRate, yourErrorRate = (float)ErrorRate / 1000;

	passRate = (SNR == 10) ? 0.12 : 0.01;
	std::cout << "----------------------------------------------------------------------------------------------------" << std::endl;
	if (ErrorRate / 1000 < passRate) {
		std::cout << "Congratulations !!!! You Pass the Test !!!" << std::endl;
		std::cout << "Your Data Error Rate is: " << yourErrorRate << " The Goal Data Error Rate is 0.12 for 10dB and 0.01 for 15dB" << std::endl;
	} else {
		std::cout << "Fail !!!";
		std::cout << "'Your Data Error Rate = "<< yourErrorRate << " The Data Error Rate must be lower than 0.12" << std::endl;
	}
	std::cout << "----------------------------------------------------------------------------------------------------" << std::endl;
}

//-----------------------------------------------------------------------------------------------------
// Debug Function
//-----------------------------------------------------------------------------------------------------
void ML_Demodulate::checkInpuutY(std::vector<Complex> inputY) {
	std::cout << "Check InputY\n";
	for (int i = 0; i < inputY.size(); ++i) {
		std::cout << std::hex << inputY[i].real << "\t" << inputY[i].imag << std::endl;
	}
}

void ML_Demodulate::checkInpuutR(std::vector<std::vector<Complex>> matirxR) {
	std::cout << "Check MatrixR\n";
	for (int i = 0; i < matirxR.size(); ++i) {
		for (int j = 0; j < matirxR[i].size(); ++j) {
			std::cout << std::hex << matirxR[i][j].real << "\t" << matirxR[i][j].imag << "\t";
		}
		std::cout << std::endl;
	}
}





