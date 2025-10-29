#include "Complex.h"
#include "ML_Demodulate.h"
#include <fstream>

#define PACKET 1

int SNR = (PACKET > 3) ? 15 : 10;
const std::string inputR_FN =    "./PATTERN/packet" + std::to_string(PACKET) + "/SNR" + std::to_string(SNR) + "dB_pat_r.dat";
const std::string inputYHAT_FN = "./PATTERN/packet" + std::to_string(PACKET) + "/SNR" + std::to_string(SNR) + "dB_pat_y_hat.dat";
const std::string outputHb_FN =  "./PATTERN/packet" + std::to_string(PACKET) + "/SNR" + std::to_string(SNR) + "dB_hb.dat";

void main() {
	std::string line;
	std::ifstream inputR_file(inputR_FN);
	std::ifstream inputYHat_file(inputYHAT_FN);
	std::ifstream outputHb_file(outputHb_FN);
	std::vector<std::string> inputY_buff, inputR_buff;
	std::vector <int> goldenHb;
	ML_Demodulate ML;
	std::vector<std::vector<Complex>> matirxR;
	std::vector<Complex> inputY;
	std::vector<int>o_LLR, o_hardBit;
	int ErrorRate = 0, goldenIndex = 0;

	if (!inputR_file || !inputYHat_file || !outputHb_file) {
		std::cout << "Cannot open files !";
		exit(1);
	}
	while (std::getline(inputR_file, line)) {
		inputR_buff.push_back(line);
	}
	while (std::getline(inputYHat_file, line)) {
		inputY_buff.push_back(line);
	}
	while (std::getline(outputHb_file, line)) {
		goldenHb.push_back(std::stoi(line));
	}
	for (int i = 0; i < inputR_buff.size(); ++i) {
		//std::cout << i << std::endl;
		ML.getR(inputR_buff[i], matirxR);
		ML.getY(inputY_buff[i], inputY);
		ML.ML_LLR(inputY, matirxR, o_LLR, o_hardBit);
		ErrorRate += ML.validateOutput(o_LLR, o_hardBit, goldenHb, goldenIndex);
		o_LLR.clear();
		o_hardBit.clear();
		goldenIndex += 8;
		std::cout << i << std::endl;
	}
	ML.validateErrorRate(ErrorRate, SNR);
	
}

